require! {
    azure
    fs
    async
    './DirScanner'
    './FileUploader'
    '../config.json'
}

blobService = azure.createBlobService config.storage_name, config.storage_key
baseDir = "C:\\www\\volebni-mapy"
fileUploader = new FileUploader do
    baseDir           : baseDir
    targetPrefix      : "foo"
    targetContainer   : "test"
    blobService       : blobService
    uploadConcurrency : 40

dirScanner = new DirScanner baseDir
    ..on \file fileUploader~upload
    ..ignore "node_modules"
    ..ignore /^\./
    ..start!
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
