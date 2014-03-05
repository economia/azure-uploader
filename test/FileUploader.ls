require! {
    expect : "expect.js"
    "../lib/FileUploader.js"
    fs
    async
    zlib
}

test = it
dir = "#__dirname/fupload"
compressibleFile = "#dir/1.html"
anotherCompressibleFile = "#dir/1.css"
uncompressibleFile = "#dir/1.jpg"

describe "FileUploader" ->
    before ->
        try => fs.mkdirSync dir
        try => fs.writeFileSync compressibleFile, "compressible"
        try => fs.writeFileSync anotherCompressibleFile, "compressible"
        try => fs.writeFileSync uncompressibleFile, "uncompressible"
    after ->
        fs.unlinkSync compressibleFile
        fs.unlinkSync anotherCompressibleFile
        fs.unlinkSync uncompressibleFile
        fs.rmdirSync dir
    uploaded = []
    onUpload = (container, targetPath, path, options, cb) ->
        (err, data) <~ fs.readFile path
        uploaded.push {container, targetPath, path, options, data}
        setTimeout cb, 10

    fileUploader = null
    baseDir           = dir
    targetPrefix      = "prefix"
    targetContainer   = "target-container"
    blobService       = {}
        ..createBlockBlobFromFile = onUpload
    uploadConcurrency = 2
    test "should initialize" ->
        fileUploader := new FileUploader {baseDir, targetPrefix, targetContainer, blobService, uploadConcurrency}

    test "should accept file queue" ->
        fileUploader.upload compressibleFile
        fileUploader.upload anotherCompressibleFile
        fileUploader.upload uncompressibleFile

    test "should finish mock-uploading" (done) ->
        <~ fileUploader.once \end
        done!

    test "should correctly pass container" ->
        for file in uploaded => expect file.container .to.equal targetContainer

    test "should set correct target filenames" ->
        correctDestinations =
            "#targetPrefix/1.html"
            "#targetPrefix/1.css"
            "#targetPrefix/1.jpg"

        for file in uploaded => expect correctDestinations .to.contain file.targetPath

    test "should compress compressible files and set correct headers" (done) ->
        compressibles = ["#targetPrefix/1.html" "#targetPrefix/1.css"]
        compressible = uploaded.filter -> it.targetPath in compressibles
        <~ async.each compressible, (file, cb) ->
            (err, data) <~ zlib.gunzip file.data
            expect data.toString! .to.eql "compressible"
            expect file.options .to.have.property \contentEncoding \gzip
            cb!
        done!

    test "should upload originals of uncompressible files" ->
        uncompressibles = ["#targetPrefix/1.jpg"]
        uncompressible = uploaded.filter -> it.targetPath in uncompressibles
        for file in uncompressible
            expect file.data.toString! .to.eql "uncompressible"

    describe "error handling" ->
        uploaded = []
        failed = []
        fileUploader = null
        unreliableUpload = (container, targetPath, path, options, cb) ->
            output = {container, targetPath, path, options}
            if options.contentEncoding
                failed.push output
                <~ setTimeout _, 10
                cb "Error pyco"
            else
                uploaded.push output
                setTimeout cb, 10

        blobService       = {}
            ..createBlockBlobFromFile = unreliableUpload

        test 'should try to upload files' (done) ->
            fileUploader := new FileUploader {baseDir, targetPrefix, targetContainer, blobService, uploadConcurrency}
            fileUploader.upload compressibleFile
            fileUploader.upload anotherCompressibleFile
            fileUploader.upload uncompressibleFile
            <~ fileUploader.once \end
            done!

        test 'should detect failed files' ->
            expect fileUploader.failed .to.have.length 2

        test 'should retry' (done) ->
            fileUploader.retry!
            <~ fileUploader.once \end
            expect failed.length .to.equal 4
            done!
