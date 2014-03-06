require! {
    azure
    fs
    async
    './DirScanner'
    './FileUploader'
    './utils'
    prompt
    commander
}
commander
    .usage '[options] <directory>'
    .version '0.0.1'
    .option '-y, --use-config' 'Use config'
    .option '-a, --upload-all' 'Upload all files (only with -y)'
    .option '-m, --upload-modified' 'Upload only files modified since last upload (only with -y)'
    .parse process.argv
[dir] = commander.args
commander.help! if not dir
baseDir = fs.realpathSync dir
(err, {config, blobService}) <~ utils.get-config baseDir, commander

fileUploader = new FileUploader do
    baseDir           : baseDir
    targetPrefix      : config.prefix
    targetContainer   : config.container_name
    blobService       : blobService
    uploadConcurrency : config.concurrency

dirScanner = new DirScanner baseDir
    ..on \file fileUploader~upload
    ..ignoreName "node_modules"
    ..ignoreName /^\./
if config.modified_since
    dirScanner.newerThan that
applyIgnores = (method, ignoreArray) ->
    return unless ignoreArray?length
    for regexOrString in ignoreArray
        if typeof! regexOrString == 'Array'
            method new RegExp ...regexOrString
        else
            method regexOrString

applyIgnores dirScanner~ignoreName, config.ignore_name
applyIgnores dirScanner~ignorePath, config.ignore_path
dirScanner.start!
<~ dirScanner.once \end
<~ fileUploader.once \end
lastFailCount = +Infinity
successCount = 0
<~ async.whilst do
    *   ->
            successCount += fileUploader.uploaded
            if fileUploader.failed.length
                if fileUploader.failed.length == lastFailCount
                    console.log "Unable to upload following files:"
                    console.log fileUploader.failed.join "\n"
                    no
                else
                    lastFailCount := fileUploader.failed.length
                    console.log "#lastFailCount files failed to upload, retrying"
                    yes
            else
                console.log "All #{successCount} files uploaded successfully"
                no
    *   (cb) ->
            fileUploader.retry!
            <~ fileUploader.once \end
            cb!
