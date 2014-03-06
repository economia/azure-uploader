require! {
    expect : "expect.js"
    "../lib/DirScanner.js"
    fs
}

test = it
dir = "#__dirname/dirscan"
filesToCreate =
    "#dir/1.txt"
    "#dir/2.txt"
    "#dir/3.txt"
    "#dir/subdir/1.txt"
    "#dir/subdir/2.txt"
    "#dir/subdir/ignore.txt"
    "#dir/subdir/.doDonUpload.txt"
    "#dir/subdir/not-ignore.txt"
    "#dir/ignore/1.txt"
deleteFiles = ->
    for file in filesToCreate
        fs.unlinkSync file
    fs.rmdirSync "#dir/subdir"
    fs.rmdirSync "#dir/ignore"
    fs.rmdirSync dir
createFiles = ->
    try => fs.mkdirSync dir
    try => fs.mkdirSync "#dir/subdir"
    try => fs.mkdirSync "#dir/ignore"
    for file in filesToCreate
        try => fs.writeFileSync file, "--"
describe "DirScanner" ->
    before ->
        createFiles!
    after ->
        deleteFiles!

    describe "basic file discovery" ->
        dirScanner = null
        files = []
        test "should initialize" ->
            dirScanner := new DirScanner dir
                ..on \file -> files.push it

        test "should scan for files" (done) ->
            dirScanner.start!
            <~ dirScanner.once \end
            done!

        test "should find all the files in root directory" ->
            expect files .to.contain "#dir/1.txt"
            expect files .to.contain "#dir/2.txt"
            expect files .to.contain "#dir/3.txt"

        test "should not export whole directories" ->
            expect files .to.not.contain "#dir/subdir"
            expect files .to.not.contain "#dir/subdir/"

        test "should find files in subdirectories" ->
            expect files .to.contain "#dir/subdir/1.txt"
            expect files .to.contain "#dir/subdir/2.txt"

    describe "ignoring paths" ->
        dirScanner = null
        files = []
        before (done) ->
            dirScanner := new DirScanner dir
                ..on \file -> files.push it
                ..ignorePath "subdir/ignore.txt"
                ..ignorePath /^ignore\//
                ..start!
            <~ dirScanner.once \end
            done!

        test "should not find paths ignored by string" ->
            expect files .to.not.contain "#dir/subdir/ignore.txt"

        test "should not find paths ignored by regex" ->
            expect files .to.not.contain "#dir/ignore/1.txt"

        test "should not mistakenly ignore files" ->
            expect files .to.contain "#dir/subdir/not-ignore.txt"

    describe "ignoring file/directory names" ->
        dirScanner = null
        files = []
        before (done) ->
            dirScanner := new DirScanner dir
                ..on \file -> files.push it
                ..ignoreName "ignore.txt"
                ..ignoreName /^\./
                ..start!
            <~ dirScanner.once \end
            done!

        test "should ignore files by string" ->
            expect files .to.not.contain "#dir/subdir/ignore.txt"

        test "should ignore files by regexp" ->
            expect files .to.not.contain "#dir/subdir/.doDonUpload.txt"

        test "should not mistakenly ignore files" ->
            expect files .to.contain "#dir/subdir/not-ignore.txt"

    describe "filtering by last modified date" ->
        now = new Date!
        nextMinute = new Date!
            ..setTime now.getTime! + 60_000
        nextTwoMinutes = new Date!
            ..setTime now.getTime! + 120_000

        dirScanner = null
        files = []
        before (done) ->
            fs.utimes "#dir/1.txt", nextTwoMinutes, nextTwoMinutes
            dirScanner := new DirScanner dir
                ..on \file -> files.push it
                ..newerThan nextMinute
                ..start!
            <~ dirScanner.once \end
            done!

        test "should find only files modified after a date" ->
            expect files .to.eql ["#dir/1.txt"]
