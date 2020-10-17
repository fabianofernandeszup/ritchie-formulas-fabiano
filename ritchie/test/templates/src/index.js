const run = require("./formula/formula")

const TEMPLATE = process.env.TEMPLATE
const SCENARIO = process.env.SCENARIO

run(TEMPLATE, SCENARIO)
