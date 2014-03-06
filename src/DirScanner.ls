require! {
    fs
    async
    events.EventEmitter
}

module.exports = class DirScanner extends EventEmitter
    (@baseDir) ->
        @ignoredNames = []
        @ignoredPaths = []
        @filesFound = []
        @baseDirCharactersToStrip = @baseDir.length
        if @baseDir[*-1] not in <[ / \\ ]> then @baseDirCharactersToStrip += 1

    start: (cb) ->
        <~ @scandir @baseDir
        @emit \end
        cb?!

    ignoreName: (stringOrRegex) ->
        @ignoredNames.push stringOrRegex
        @

    ignorePath: (stringOrRegex) ->
        @ignoredPaths.push stringOrRegex
        @

    filterName: (filename) ->
        @matchStringOrRegex @ignoredNames, filename

    filterPath: (filepath) ->
        relativePath = filepath.substr @baseDirCharactersToStrip
        @matchStringOrRegex @ignoredPaths, relativePath

    matchStringOrRegex: (stringOrRegexArray, testString) ->
        for stringOrRegex in stringOrRegexArray
            if stringOrRegex.test
                if stringOrRegex.test testString
                    return false
            else if testString == stringOrRegex
                return false
        return true

    scandir: (basedir, cb) ->
        (err, contents) <~ fs.readdir basedir
        throw err if err
        validNames = contents.filter @~filterName
        paths = validNames.map -> basedir + "/" + it
        validPaths = paths.filter @~filterPath
        <~ async.each validPaths, (path, cb) ~>
            (err, stat) <~ fs.stat path
            if stat.isDirectory!
                (err, subFiles) <~ @scandir path
                cb!
            else
                @filesFound.push path
                @emit \file path
                cb!
        cb?!
