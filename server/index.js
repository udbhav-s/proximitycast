const express = require('express');
const session = require('express-session');
const { exec } = require("child_process");

const profileList = {};
const debug = true;

const range = 100;

const createKeys = () => {
  return new Promise((res, rej) => {
    exec("a.exe createKeys", (error, stdout, stderr) => {
      if (error) {
          rej(error.message);
      }
      if (stderr) {
          rej(stderr);
      }
      const [publicKey, privateKey] = stdout.split("\n");
      res({ publicKey, privateKey });
    });
  });
};

const getDistance = (publicKey, privateKey, ciphertext) => {
  return new Promise((res, rej) => {
    exec(`a.exe decryptDistance ${publicKey} ${privateKey} ${ciphertext}`, (error, stdout, stderr) => {
      if (error) {
          rej(error.message);
      }
      if (stderr) {
          rej(stderr);
      }

      if (debug) console.log("decryptDistance k result: ", stdout);
      
      const num = parseInt(stdout);
      res(num);
    });
  });
};

const main = async () => {
  const { publicKey, privateKey } = await createKeys();

  const app = express();

  app.use(express.static('static'));
  app.use(session({
    secret: 'secret'
  }));
  app.use(express.urlencoded({ extended: true }));
  app.use(express.json());

  app.get("/", (req, res) => {
    res.send("Hello, World!");
  });

  app.get("/publicKey", (req, res) => {
    res.send({ publicKey });
  });

  app.get("/range", (req, res) => {
    res.send({ range });
  });

  app.post("/profile/create", (req, res) => {
    const {
      publicKey,
      locationCiphertexts: lc,
      peerId,
    } = req.body;

    if (publicKey in profileList) {
      // res.send({ error: "already exist!! >:(" });
      console.log("Got create for existing session");
      // return;
    }

    profileList[publicKey] = {
      publicKey,
      locationCiphertexts: {
        sumOfSquares: lc.sumOfSquares,
        twoX: lc.twoX,
        twoY: lc.twoY,
      },
      peerId,
    };

    // TODO: Verify pubkey with message signature
    req.session.publicKey = publicKey; 

    console.log("New profile uploaded");
    console.log(profileList[publicKey]);

    res.send({
      success: true
    });
  });

  app.get("/profiles", (req, res) => {
    let profiles = Object.entries(profileList).map(p => p[1]);
    if (req.session.publicKey)
      profiles = profiles.filter((p) => p.publicKey !== req.session.cookie.publicKey);
    res.send({
      profiles
    });
  });

  app.post("/logout", (req, res) => {
    console.log("Deleting profile: " + req.session.publicKey);
  
    delete profileList[req.session.publicKey];
    delete req.session.publicKey;
    
    res.send({ success: true });
  });

  app.post("/verifyDistance", (req, res) => {
    const { d2PlusK, encK } = req.body;
    console.log("d2PlusK: ", d2PlusK);

    getDistance(publicKey, privateKey, encK).then((k) => {
      const diff = d2PlusK - k;

      console.log("Got diff: " + diff);

      res.send({
        isNearby: diff < 0
      });
    });
  });

  app.listen(process.env.PORT || 3000, () => console.log("App running"));
};

main();