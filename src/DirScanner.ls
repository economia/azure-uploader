require! {
    fs
    async
    events.EventEmitter
}

module.exports = class DirScanner extends EventEmitter
    (@dir) ->
        @ignores = []
        @filesFound = []

    start: (cb) ->
        <~ @scandir @dir
        @emit \end
        cb?!

    ignore: (stringOrRegex) ->
        @ignores.push stringOrRegex
        @

    filterFile: (filename) ->
        for stringOrRegex in @ignores
            if stringOrRegex.test
                if stringOrRegex.test filename
                    return false
            else if filename == stringOrRegex
                return false
        return true

    scandir: (basedir, cb) ->
        (err, contents) <~ fs.readdir basedir
        throw err if err
        contents .= filter @~filterFile
        <~ async.each contents, (fileOrDir, cb) ~>
            path = "#basedir/#fileOrDir"
            (err, stat) <~ fs.stat path
            if stat.isDirectory!
                (err, subFiles) <~ @scandir path
                cb!
            else
                @filesFound.push path
                @emit \file path
                cb!
        cb?!
