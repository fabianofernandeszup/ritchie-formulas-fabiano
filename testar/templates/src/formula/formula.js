const { exec, execSync } = require("child_process")
const fs = require('fs')
const path = require('path')
const homedir = require('os').homedir()
const stripAnsi = require('strip-ansi')

const stdinOld = '{"sample_text":"Text","sample_list":"in_list1","sample_bool":"true"}'
const stdinNew = '{"input_text":"Text","input_boolean":"true","input_list":"toils","input_password":"pass"}'

let templatesLanguages = [
    {
        language: "csharp",
        stdin: stdinNew,
        stdout: `Hello World!
My name is Text.
I’ve already created formulas using Ritchie.
Today, I want to automate toils.
My secret is pass.`
    },
    {
        language: "go",
        stdin: stdinNew,
        stdout: `Hello world!
[32mMy name is Text.
[0m[34mI’ve already created formulas using Ritchie.
[0m[33mToday, I want to automate toils.
[0m[36mMy secret is pass.`
    },
    {
        language: "java8",
        stdin: stdinNew,
        stdout: `Hello World!
[32mMy name is Text.[39m
[36mI’ve already created formulas using Ritchie.[39m
[33mToday, I want to automate toils.[39m
[35mMy secret is pass.[39m`
    },
    {
        language: "java11",
        stdin: stdinOld,
        stdout: `Hello World!
You receive Text in text.
You receive in_list1 in list.
You receive true in boolean.`
    },
    {
        language: "node",
        stdin: stdinNew,
        stdout: `Hello World!
[32mMy name is undefined[39m
[31mI’m excited in creating new formulas using Ritchie.[39m
[33mToday, I want to automate undefined[39m
[36mMy secret is undefined[39m`
    },
    {
        language: "php",
        stdin: stdinOld,
        stdout: `Hello World!
[2;32mYou receive Text in text.
[2;31mYou receive in_list1 in list.
[2;34mYou receive true in boolean.`
    },
    {
        language: "powershell",
        stdin: stdinOld,
        stdout: `Hello, World!
You receive Text in text.
You receive in_list1 in list. 
You receive true in boolean.`
    },
    {
        language: "python3",
        stdin: stdinOld,
        stdout: `Hello World!
[38;5;2mYou receive Text in text.[0m
[38;5;1mYou receive in_list1 in list.[0m
[38;5;3mYou receive true in boolean.[0m`
    },
    {
        language: "ruby",
        stdin: stdinOld,
        stdout: `Hello World!
[0;31;49mYou receive Text in text.[0m
[0;32;49mYou receive in_list1 in list.[0m
[0;34;49mYou receive true in boolean.[0m`
    },
    {
        language: "rust",
        stdin: stdinNew,
        stdout: `Hello World!
My name is Text.
I’ve already created formulas using Ritchie.
Today, I want to automate toils.
My secret is pass.`
    },
    {
        language: "shell-bat",
        stdin: stdinNew,
        stdout: `Hello World! 
[32mMy name is Text.[0m
[34mI've already created formulas using Ritchie.[0m
[33mToday, I want to automate toils.[0m
[36mMy secret is pass.[0m`
    },
    {
        language: "typescript",
        stdin: stdinNew,
        stdout: `Hello World!
My name is Text.
I’ve already created formulas using Ritchie.
Today, I want to automate toils.
My secret is pass.`
    }
]

//templatesLanguages = templatesLanguages.filter((item) => ['go'].indexOf(item.language) >= 0)

async function Run(input1, input2, input3) {
    console.log("***********************************")
    console.log("* Test Ritchie Forulas Templates  *")
    console.log("***********************************")

    createFormulas()

    // Local
    console.log("***********************************")
    console.log("* 1 - Runnning Local Tests        *")
    console.log("***********************************")
    await runTests(false, true)

    // Local Twice
    console.log("***********************************")
    console.log("* 2 - Runnning Local Twice Tests  *")
    console.log("***********************************")
    await runTests(false, false)

    // Docker
    console.log("***********************************")
    console.log("* 3 - Runnning Docker Tests       *")
    console.log("***********************************")
    await runTests(true, true)

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

function createFormulas() {
    console.log('Creating formulas...')

    // Copy formulas
    execSync('rm -rf '+homedir+'/.rit/repos/local/test-formula-template')
    execSync('mkdir '+homedir+'/.rit/repos/local/test-formula-template')
    execSync('cp -r '+homedir+'/.rit/repos/commons/templates/create_formula/languages/* '+homedir+'/.rit/repos/local/test-formula-template')

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
      execSync('rm -rf '+homedir+'/.rit/repos/local/test-formula-template/'+template.language+'/bin')
    }

    // Run Command
    let flagDocker = docker ? '--docker' : ''
    let command = 'echo \''+template.stdin+'\' | rit test-formula-template '+template.language+' --stdin ' + flagDocker

    exec(command, (error, stdout, stderr) => {
        if (error) {
            console.log("["+template.language+"] - [31mERROR[39m")
            registerErrorLog(docker, template.language, `error: ${error.message}`)
            return resolve(error)
        }
        if (stderr) {
            console.log("["+template.language+"] - [31mSTDERR[39m")
            registerErrorLog(docker, template.language, `stderr: ${stderr}`)
            return resolve(stderr)
        }

        if (stripAnsi(stdout).trim().indexOf(stripAnsi(template.stdout).trim()) >= 0) {
            console.log("["+template.language+"] - [32mPASS[39m")
        } else {
            console.log("["+template.language+"] - [31mFAIL OUTPUT[39m")
            let output = 'Template fail output\n'
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
    fs.writeFileSync(fileName+sufix+'.log', content, {flag:'w'}, (err) => {});
}

const formula = Run
module.exports = formula
