require! {
    fs
    prompt
    async
    azure
}

configFileName = "azure-upload-settings.json"

module.exports.get-config = (baseDir, commander, cb) ->
    (err, exists) <~ detect-configfile baseDir
    if exists
        (err, config) <~ load-configfile baseDir
        (err, use_config) <~ prompt-use-config commander, config
        if use_config
            blobService = create-blobservice config
            modified_since = new Date config.previous_run_date
            config.previous_run_date = new Date!toString!
            save-config baseDir, config
            (err, use_modified_since) <~ prompt-use-modified-since commander, modified_since
            if use_modified_since
                config.modified_since = modified_since
            cb null, {config, blobService}
        else
            init-cli baseDir, cb
    else
        init-cli baseDir, cb

prompt-use-config = (commander, config, cb) ->
    if commander.use-config
        cb null true
    else
        prefix_text = if config.prefix then "/#that" else ""
        console.log "Found upload config - account #{config.storage_name}, container #{config.container_name}"
        console.log "Address: #{config.container_url}#{prefix_text}"
        console.log "Concurrency #{config.concurrency}"
        console.log "(on startup, set -y to suppress this message)"
        config_prompt =
            name: "use_config"
            description: "Use config [y/n]"
            default: "y"
        (err, {use_config}) <~ prompt.get [config_prompt]
        cb null, use_config.toLowerCase! == 'y'

prompt-use-modified-since = (commander, modified_since_date, cb) ->
    if commander.upload-modified
        cb null true
    else if commander.upload-all
        cb null false
    else
        console.log "Last upload was at #{modified_since_date}. Upload only files modified since then?"
        console.log "(on startup, set -m to auto-yes or -a to auto-no)"
        modified_since_prompt =
            name: "use_modified_since"
            description: "Upload only files modified since last upload [y/n]"
            default: "y"
        (err, {use_modified_since}) <~ prompt.get [modified_since_prompt]
        cb null, use_modified_since.toLowerCase! == 'y'


init-cli = (baseDir, cb) ->
    containers = null
    blobService = null
    config = {}
    <~ async.whilst do
        -> containers is null
        (cb) ->
            storage_prompts =
                *   name: "storage_name"
                    description: "Enter your Storage Account Name"
                *   name: "storage_key"
                    description: "Enter storage's Primary Access Key"
            (err, storageData) <~ prompt.get storage_prompts
            config{storage_name, storage_key} := storageData
            try
                blobService := create-blobservice storageData
            catch e
                console.log e
                return cb!
            console.log "Getting containers list..."
            (err, data) <~ blobService.listContainers
            if err
                console.log "Invalid credentials supplied, please try again"
            else if data.length == 0
                console.log "There are no containers in this Storage Account. Please create one in Azure Portal and try again."
            else
                containers := data
            cb!

    targetContainer = null
    <~ async.whilst do
        -> targetContainer is null
        (cb) ->
            console.log "Found following containers:"
            for container, index in containers
                console.log "#{index + 1} - #{container.name.substr 0, 60}"
            container_prompt =
                name: "container_selection"
                description: "Enter the container number [1 - #{containers.length}] or name (eg. #{containers.0.name})"
            (err, {container_selection}) <~ prompt.get [container_prompt]
            index = +container_selection
            console.log index
            if index
                targetContainer := containers[index - 1]
            else
                containersMatchingName = containers.filter ->
                    it.name == container_selection
                if containersMatchingName.length
                    targetContainer := containersMatchingName.0
                else
                    console.log "Can't find container named #{container_selection} by index or name. Please try again."
            cb!
    config.container_name = targetContainer.name
    config.container_url = targetContainer.url

    prefix_prompt =
        name: "prefix"
        description: "Set container directory prefix (default none)"

    (err, {prefix}) <~ prompt.get [prefix_prompt]
    config.prefix = prefix
    prefix_text = if prefix then "/#prefix" else ""

    concurrency_prompt =
        name: "concurrency"
        description: "Upload threads to use"
        default: 40
        minimum: 1
        maximum: 100

    (err, {concurrency}) <~ prompt.get [concurrency_prompt]
    config.concurrency = +concurrency || 40
    console.log "By default, uploader ignores all files starting with . (.git, .htaccess...) and node_modules."
    console.log "Turn off to upload all files. Edit config file to tweak your filter."
    default_ignores_prompt =
        name: "use_default_ignores"
        description: "Use default ignores [y/n]"
        default: "y"
    (err, {use_default_ignores}) <~ prompt.get [default_ignores_prompt]
    if use_default_ignores.toLowerCase! == 'y'
        config.ignore_name =
            ["node_modules" "i"]
            ["^\\." ""]

    config.previous_run_date = new Date!toString!
    console.log "Ready to upload directory #{baseDir} to #{targetContainer.name} (#{targetContainer.url}#{prefix_text})."
    console.log "Save settings to #{baseDir}/#{configFileName}? You will not need to enter all credentials again."
    console.log "(storage key will be saved in plaintext)"
    save_prompt =
        name: "save"
        description: "Save settings [y/n]"
        default: "y"

    (err, {save}) <~ prompt.get [save_prompt]
    if save.toLowerCase! == 'y'
        (err) <~ save-config baseDir, config
        console.log "Config saved" if not err

    cb null, {config, blobService}


save-config = (baseDir, config, cb) ->
    (err) <~ fs.writeFile "#baseDir/#configFileName", JSON.stringify config, true, 4
    cb? err

create-blobservice = (config) ->
    azure.createBlobService do
        config.storage_name
        config.storage_key

detect-configfile = (baseDir, cb) ->
    (exists) <~ fs.exists "#baseDir/#configFileName"
    cb null, exists

load-configfile = (baseDir, cb) ->
    (err, data) <~ fs.readFile "#baseDir/#configFileName"
    cb null, JSON.parse data
