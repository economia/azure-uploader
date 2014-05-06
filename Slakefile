require! fs
require! child_process.exec

option 'currentfile' 'Latest file that triggered the save' 'FILE'

test-script = (file) ->
    [srcOrTest, ...fileAddress] = file.split /[\\\/]/
    fileAddress .= join '/'
    <~ build-all
    cmd = "mocha --compilers ls:livescript -R tap --bail #__dirname/test/#fileAddress"
    (err, stdout, stderr) <~ exec cmd
    niceTestOutput stdout, stderr, cmd

test-all = (cb) ->
    <~ build-all
    cmd = "mocha --compilers ls:livescript #__dirname/test/"
    (err, stdout, stderr) <~ exec cmd
    console.error stderr if stderr
    console.error err if err
    console.log stdout

build-all = (cb) ->
    (err, stdout, stderr) <~ exec "lsc -o #__dirname/lib -c #__dirname/src"
    console.log err if err
    console.log stderr if stderr
    (err, data) <~ fs.readFile "#__dirname/lib/cli.js"
    cliFile = data.toString!
    cliFileWithHeader = '#!/usr/bin/env node' + "\n\n" + data
    fs.writeFile "#__dirname/lib/cli.js" cliFileWithHeader
    cb?!

task \build ->
    <~ build-all

task \test ->
    test-all!

task \test-script ({currentfile}) ->
    currentfile .= replace "#__dirname" ""
    currentfile .= slice 1 # remove leading /
    test-script currentfile

niceTestOutput = (test, stderr, cmd) ->
    lines         = test.split "\n"
    oks           = 0
    fails         = 0
    out           = []
    shortOut      = []
    disabledTests = []
    for line in lines
        if 'ok' == line.substr 0, 2
            ++oks
        else if 'not' == line.substr 0,3
            ++fails
            out.push line
            shortOut.push line.match(/not ok [0-9]+ (.*)$/)[1]
        else if 'Disabled' == line.substr 0 8
            disabledTests.push line
        else if line and ('#' != line.substr 0, 1) and ('1..' != line.substr 0, 3)
            console.log line# if ('   ' != line.substr 0, 3)
    if oks && !fails
        console.log "Tests OK (#{oks})"
        disabledTests.forEach -> console.log it
    else
        #console.log "!!!!!!!!!!!!!!!!!!!!!!!    #{fails}    !!!!!!!!!!!!!!!!!!!!!!!"
        if out.length
            console.log shortOut.join ", "#line for line in shortOut
        else
            console.log "Tests did not run (error in testfile?)"
            console.log test
            console.log stderr
            console.log cmd
