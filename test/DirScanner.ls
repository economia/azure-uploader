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

    dirScanner = null
    files = []
    onFile = -> files.push it
    test "should initialize" ->
        dirScanner := new DirScanner dir
            ..on \file onFile
            ..ignore "ignore.txt"
            ..ignore new RegExp "^ignore$"
            ..ignore /^\./

    test "should scan for files" (done) ->
        dirScanner.start!
        <~ dirScanner.on \end
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

    test "should not find files ignored by string" ->
        expect files .to.not.contain "#dir/subdir/ignore.txt"

    test "should not find files ignored by regexp" ->
        expect files .to.not.contain "#dir/ignore/1.txt"
        expect files .to.not.contain "#dir/subdir/.doDonUpload.txt"

    test "should not mistakenly ignore files" ->
        expect files .to.contain "#dir/subdir/1.txt"



