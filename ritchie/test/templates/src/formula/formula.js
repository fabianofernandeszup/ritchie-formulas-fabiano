const { exec, execSync } = require("child_process")
const fs = require('fs')
const fse = require('fs-extra')
const path = require('path')
const homedir = require('os').homedir()
const stripAnsi = require('strip-ansi')

// Configs
let currentPwd = ''
const stdinOld = '{"sample_text":"Text","sample_list":"in_list1","sample_bool":"true"}'
const stdinNew = '{"input_text":"Text","input_boolean":"true","input_list":"toils","input_password":"pass"}'

const stdoutOld = `Hello World!
You receive Text in text.
You receive in_list1 in list.
You receive true in boolean.`

const stdoutNew = `Hello World!
My name is Text.
I've already created formulas using Ritchie.
Today, I want to automate toils.
My secret is pass.`

let templatesLanguages = [
    {
        language: "csharp",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "go",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "java8",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "java11",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "node",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "php",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "powershell",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "python3",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "ruby",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "rust",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "shell-bat",
        stdin: stdinNew,
        stdout: stdoutNew
    },
    {
        language: "typescript",
        stdin: stdinNew,
        stdout: stdoutNew
    }
]

async function Run(templates, scenario, pwd) {
    this.currentPwd = pwd
    console.log(this.currentPwd)
    if (templates!='all') {
        templatesLanguages = templatesLanguages.filter((item) => [templates].indexOf(item.language) >= 0)
    }

    console.log("***********************************")
    console.log("* Test Ritchie Forulas Templates  *")
    console.log("***********************************")
    createFormulas()

    // Local
    if (scenario == 'local' || scenario == 'all') {
        console.log("***********************************")
        console.log("* 1 - Runnning Local Tests        *")
        console.log("***********************************")
        await runTests(false, true)
    }

    // Local Twice
    if (scenario == 'all') {
        console.log("***********************************")
        console.log("* 2 - Runnning Local Twice Tests  *")
        console.log("***********************************")
        await runTests(false, false)
    }

    // Docker
    if (scenario == 'docker' || scenario == 'all') {
        console.log("***********************************")
        console.log("* 3 - Runnning Docker Tests       *")
        console.log("***********************************")
        await runTests(true, true)
    }

    if (scenario == 'all') {
        // Docker Twice
        console.log("***********************************")
        console.log("* 4 - Runnning Docker Twice Tests *")
        console.log("***********************************")
        await runTests(true, false)

        // Local First
        console.log("***********************************")
        console.log("* 5 - Runnning Local First Tests  *")
        console.log("***********************************")
        await runTests(false, true)

        console.log("***********************************")
        console.log("* 6 - Runnning Docker Second Tests*")
        console.log("***********************************")
        await runTests(true, false)

        // Docker First
        console.log("***********************************")
        console.log("* 7 - Runnning Docker First Tests *")
        console.log("***********************************")
        await runTests(true, true)

        console.log("***********************************")
        console.log("* 8 - Runnning Local Second Tests *")
        console.log("***********************************")
        await runTests(false, false)
    }

    console.log("***********************************")
    console.log("* Tests Finished                  *")
    console.log("***********************************")

}

function createFormulas() {
    console.log('Creating formulas...')

    // Copy formulas
    const formulaDir = `${homedir}/.rit/repos/local/test-formula-template`
    fs.rmdirSync(formulaDir, { recursive: true })
    fse.mkdirpSync(formulaDir)
    fse.copySync(`${homedir}/.rit/repos/commons/templates/create_formula/languages`, formulaDir)

    // Ajust tree.json
    let treeJson = require(path.resolve(homedir+'/.rit/repos/local/tree.json'));
    if (!treeJson.commands.some(item => item.id == 'root_test-formula-template')) {
        treeJson.commands.push({
                          "id": "root_test-formula-template",
                          "parent": "root",
                          "usage": "test-formula-template",
                          "help": "",
                          "longHelp": ""
                      })
    }
    for (template of templatesLanguages) {
        if (!treeJson.commands.some(item => item.id == "root_test-formula-template_" + template.language)) {
            treeJson.commands.push({
                              "id": "root_test-formula-template_" + template.language,
                              "parent": "root_test-formula-template",
                              "usage": template.language,
                              "help": "",
                              "longHelp": "",
                              "formula": true
                           })
        }
    }
    // Write new tree.json
    fs.writeFileSync(homedir+'/.rit/repos/local/tree.json', JSON.stringify(treeJson), {flag:'w'}, (err) => {});
    console.log("[32mDONE[39m")
}

async function runTests(docker, clearBin) {
    let execs = templatesLanguages.map(template => runExec(template, docker, clearBin));
    return new Promise(resolve => {
      Promise.all(execs)
      .then(responses => {
        resolve()
      })
  })
}

function runExec(template, docker, clearBin) {
  return new Promise((resolve, reject) => {
    // Remove Bin
    if (clearBin) {
      fs.rmdirSync(`${homedir}/.rit/repos/local/test-formula-template/${template.language}/bin`, { recursive: true })
    }

    // Run Command
    let flagDocker = docker ? '--docker' : ''
    let command
    if (process.platform === "win32") {
        command = `echo ${template.stdin} | rit test-formula-template ${template.language} --stdin ${flagDocker}`
    } else {
        command = 'echo \''+template.stdin+'\' | rit test-formula-template '+template.language+' --stdin ' + flagDocker
    }

    exec(command, (error, stdout, stderr) => {
        if (error) {
            console.log("["+template.language+"] - [31mERROR[39m")
            let output = `command: ${command}\n`
            output += `error: ${error.message}`
            registerErrorLog(docker, template.language, output)
            return resolve(error)
        }
        if (stderr) {
            console.log("["+template.language+"] - [31mSTDERR[39m")
            let output = `command: ${command}\n`
            output += `stderr: ${stderr}`
            registerErrorLog(docker, template.language, output)
            return resolve(stderr)
        }

        let stdoutFinal = stripAnsi(stdout.trim()).trim().replace(/(\r\n|\n|\r)/g, "")
        let templateStdoutFinal = stripAnsi(template.stdout.trim()).trim().replace(/(\r\n|\n|\r)/g, "")

        if (stdoutFinal.indexOf(templateStdoutFinal) >= 0) {
            console.log("["+template.language+"] - [32mPASS[39m")
        } else {
            console.log("["+template.language+"] - [31mFAIL OUTPUT[39m")
            let output = 'Template fail output\n'
            output += '------------ Command ---------------\n'
            output += command+'\n'
            output += '------------ Expected ---------------\n'
            output += stripAnsi(template.stdout).trim()
            output += '\n------------- Output ----------------\n'
            output += stripAnsi(stdout).trim()
            output += '\n---------------------------\n'
            registerErrorLog(docker, template.language, output)
        }
        resolve(stdout)
    })
  })
}

function registerErrorLog(docker, command, content) {
    const fileName = command.replace(/ /g, "_");
    const sufix = docker ? '_docker' : ''
    const fileNameFull = fileName +  sufix + '.log'
    const dirName = this.currentPwd + '/templates-logs'
    console.log(`${dirName}/${fileNameFull}`)

    fs.rmdirSync(dirName, { recursive: true })
    fs.mkdirSync(dirName)

    fs.writeFile(`${dirName}/${fileNameFull}`, content, (err) => {});
}

const formula = Run
module.exports = formula
