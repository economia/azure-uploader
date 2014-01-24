require! {
    azure
    fs
    async
    nconf
    http
    mime
    zlib
}

base = "C:\\www\\prezidentske-mapy-2013-2-front\\"
containerName = "projects"

scandir = (basedir, cb) ->
    (err, contents) <~ fs.readdir basedir
    <~ async.each contents, (fileOrDir, cb) ->
        path = "#basedir/#fileOrDir"
        (err, stat) <~ fs.stat path
        if stat.isDirectory!
            <~ scandir path
            cb!
        else
            queue.push path
            cb!
    cb!

isCompressible = (path) ->
    m = mime.lookup path
    "text/" == m.substr 0, 5 or m in <[application/json application/javascript]>


getCompressedPath = (path, cb) ->
    stream = fs.createReadStream path
    targetPath = path + ".azure.gz"
    target = fs.createWriteStream targetPath
    compressor = zlib.createGzip level: 9 memLevel: 9
    stream.pipe compressor
    compressor.pipe target
    <~ compressor.on \end
    cb null targetPath

getUploadableProperties = (originalPath, cb) ->
    options = {}
    if not isCompressible originalPath
        path = originalPath
        cb null {path, options}
        return
    (err, path) <~ getCompressedPath originalPath
    options.contentEncoding = \gzip
    options.contentType = options.contentTypeHeader = mime.lookup originalPath
    cb null {path, options}

queue = []
console.log "Scanning for files"
<~ scandir base
console.log "Uploading #{queue.length} files"

blobService = azure.createBlobService []

http.globalAgent.maxSockets = 50
i = 0
len = queue.length
percent = Math.round len / 1000
failed = []
async.eachLimit queue, 40, (file, cb) ->
    endname = file.replace base + "/", ""
    endname = "projects/" + endname
    (err, {path, options}) <~ getUploadableProperties file
    (err) <~ blobService.createBlockBlobFromFile containerName, endname, path, options
    if options.contentEncoding == \gzip
        fs.unlink path
    if err
        console.error that
        console.error file
        failed.push file
        fs.writeFile "failed2.txt", failed.join "\n"
    i++
    if 0 is i % percent or i == len
        console.log "#{(0.1 * Math.round i / len * 1000).toFixed 1}% (#i)"
    setImmediate cb


