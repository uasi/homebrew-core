const { Octokit } = require("@octokit/action");

const octokit = new Octokit();

const NUMBER_OF_ATTEMPTS = 3000;
const TIME_BETWEEN_ATTEMPTS_SECONDS = 5000;

async function is_runner_running () {
  for (var i=0; i < NUMBER_OF_ATTEMPTS; i++) {
    const result = await octokit.request(`GET /repos/${process.env.REPO_NAME}/actions/runners`)

    // Select the runner based on it's name
    runner = result.data["runners"].filter(function(runner) {
      return runner.name == process.env.RUNNER_NAME;
    })[0]

    if (runner.busy == false) {
      // Return "true" once the self-hosted runner is not busy anymore
      console.log("::set-output name=result::true");
      break;
    }

    await new Promise(resolve => setTimeout(resolve, TIME_BETWEEN_ATTEMPTS_SECONDS));
  }
}

is_runner_running()
