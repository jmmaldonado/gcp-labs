const express = require('express');
const app = express();
const bodyParser = require('body-parser');
app.use(bodyParser.json());
const port = process.env.PORT || 8080;
app.listen(port, () => {
  console.log('Listening on port', port);
});
app.post('/', async (req, res) => {
  const message = decodeBase64Json(req.body.message.data);
  try {
    console.log(`Execution Service: Report ${message.id} trying...`);
    executeTask();
    console.log(`Execution Service: Report ${message.id} success :-)`);
    res.status(204).send();
  }
  catch (ex) {
    console.log(`Execution Service: Report ${message.id} failure: ${ex}`);
    res.status(500).send();
  }
})
function decodeBase64Json(data) {
  return JSON.parse(Buffer.from(data, 'base64').toString());
}
function executeTask() {
  console.log('Executing task related to the message received');
}