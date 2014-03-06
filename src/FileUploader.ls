require! {
    fs
    async
    zlib
    mime
    http
    events.EventEmitter
}
module.exports = class FileUploader extends EventEmitter
    ({@baseDir, @targetPrefix, @targetContainer, @blobService, @uploadConcurrency = 40}) ->
        @queue = async.queue @~uploadFile, @uploadConcurrency
            ..drain = ~> @emit \end
        @failed = []
        @baseDirCharactersToStrip = @baseDir.length
        if @baseDir[*-1] not in <[ / \\ ]> then @baseDirCharactersToStrip += 1
        @fileCount = @uploaded = 0
        http.globalAgent.maxSockets = @uploadConcurrency

    retry: ->
        failures = @failed.slice 0
        @failed.length = @fileCount = @uploaded = 0
        failures.forEach @~upload

    upload: (filepath) ->
        ++@fileCount
        @queue.push filepath

    uploadFile: (filepath, cb) ->
        (err, {path:fileToUploadPath, options}) <~ getFileToUpload filepath
        targetPath = @getTargetPath filepath
        (err) <~ @blobService.createBlockBlobFromFile @targetContainer, targetPath, fileToUploadPath, options
        if options.contentEncoding == \gzip then fs.unlink fileToUploadPath
        if err then @failed.push filepath
        @uploaded++
        if 0 == @uploaded % 1000
            console.log "Uploaded #{@uploaded} of #{@fileCount} files (#{(@uploaded / @fileCount * 100).toFixed 2}%)"
        cb!

    getTargetPath: (filepath) ->
        sansBasedir = filepath.slice @baseDirCharactersToStrip
        @targetPrefix + "/" + sansBasedir

getFileToUpload = (originalPath, cb) ->
    options = {}
    if not isCompressible originalPath
        path = originalPath
        cb null {path, options}
        return
    (err, path) <~ compress originalPath
    options.contentEncoding = \gzip
    options.contentType = options.contentTypeHeader = mime.lookup originalPath
    cb null {path, options}


isCompressible = (path) ->
    m = mime.lookup path
    "text/" == m.substr 0, 5 or m in <[application/json application/javascript]>

compress = (path, cb) ->
    stream = fs.createReadStream path
    targetPath = path + ".azure.gz"
    target = fs.createWriteStream targetPath
    compressor = zlib.createGzip level: 9 memLevel: 9
    stream.pipe compressor
    compressor.pipe target
    <~ compressor.on \end
    cb null targetPath
