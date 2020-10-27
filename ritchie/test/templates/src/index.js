const run = require("./formula/formula")

const TEMPLATE = process.env.TEMPLATE
const SCENARIO = process.env.SCENARIO
const CURRENT_PWD = process.env.CURRENT_PWD

run(TEMPLATE, SCENARIO, CURRENT_PWD)
