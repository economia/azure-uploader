# Azure Uploader
A tool to easily upload a directory and all its subdirectories to Microsoft Azure Blob Storage container.

Built on Node, written in [LiveScript](http://livescript.net/)

## Key Features
- Provides an easy to use keyboard-interactive terminal
- Gzips all files where it makes sense, cutting down your transfer costs
- Supports differential upload (transfer only files which have been modified since last upload)
- Allows filtering of uploaded files (won't upload your git folder)
- Supports multithreaded upload (reaching ~150 small files/second)

## Installation

    npm install -g azure-uploader

## Usage

    azure-upload path/to/dir-root

You will then be guided by keyboard-interactive prompt.

> You will need your Storage Account name and Access Key. In Azure Management Portal, go to Storage tab, select an Account (do not go into it's dashboard, just select it) and in the bottom menu, select Manage Access Keys.

## Advanced options

After you setup your directory for upload, you will be asked whether you wish to save the config for later use. If you choose yes, a `azure-upload-settings.json` file will be created in the uploaded directory root. You will then be able to upload the directory without entering your credentials and upload only files modified since last upload (using [stat's](http://nodejs.org/api/fs.html#fs_fs_stat_path_callback) [mtime](http://nodejs.org/api/fs.html#fs_class_fs_stats)). You will be asked whether you wish to use the config files and upload all or modified files in a keyboard-interactive interface.

You can also pass these choices as arguments on startup, with `-y` to use config file (you will be taken directly to all files / modified only question), `-a` to upoad all files and `-m` to upload only modified files. Note that `-a` or `-m` without `-y` will still invoke a prompt whether to use the config file.

To non-interactively upload only modified files in a folder, use `azure-upload path/to/dir-root -ym`. Similarly, use `azure-upload path/to/dir-root -ya` to upload all files.

## Ignoring specified files

By default, uploader ignores all files and directories starting with `.` character (.git etc.) and `node_modules` directory anywhere in project. You can turn this option off when setting up the upload. Unless you tweak `azure-upload-settings.json`, the config file is also never uploaded.

More advanced ignore options can be accessed in `azure-upload-settings.json`, with keys `ignore_name` and `ignore_path`.
- `ignore_name` ignores files and directories by their individual names - eg. to ignore `basedir/foo/bar.txt`, you might enter `bar.txt` (and to ignore all files in `foo` directory, you would enter `foo`)
- `ignore_path` works on the whole relative path from the basedir - meaning string `foo/bar.txt` would match `basedir/foo/bar.txt`, but not `basedir/subfolder/foo/bar.txt` (but RegExp without starting `^` would match both!)

Both rulesets are typed in as arrays, with individual rules either strings or two-sized arrays. If the rule is a string, an exact match (===) is required. If the rule is an array, it is considered as RegExp(rule[0], rule[1]), i.e. first array element serves as the pattern, second as flags (most commonly `i` for case-insensitive match).

Neither ruleset matches absolute path up to and including the basedir.

## Licence (MIT)
Copyright (c) 2014 Economia, a.s.

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
