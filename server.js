require("dotenv").config();
const express = require("express");
const path = require("path");
const app = express();
const middleware = require("./app/middlewares/index");
const {currencyConverter} = require("./app/utils/index");
const cors = require("cors");
const https = require("https");
const device = require("express-device");
const fs = require("fs");
const fileUpload = require('express-fileupload');
const {
    existsSync,
    mkdirSync,
    accessSync,
    readFileSync,
    constants,
    appendFile,
    writeFile,
  } = require("fs");

  const {
    v4: uuidv4
  } = require("uuid");
  const cookieParser =  require("cookie-parser");

  app.use(express.json({
    limit: "200mb"
  }));

  app.use(
    express.urlencoded({
        extended: true,
        limit: "200mb"
    })
  );

  const {
    redisClient
  } = require("./app/utils/redisClient");
  app.use(cookieParser());

  // set a cookie
app.use(function (req, res, next) {
    if (req.cookies.token === undefined) {
      res.cookie("token", uuidv4(), {
        maxAge: 1000 * 3600 * 24 * 30 * 2,
        path: "/",
      });
    }
    next();
  });

app.set("views", path.join(__dirname, "./app/views"));
app.use(express.static(path.join(__dirname, "public")));
app.set("view engine", "ejs");

app.use(cors());
app.use(device.capture());
// app.use(require("sanitize").middleware);
app.use(fileUpload());

  //Routers
const loginRouter = require("./app/routers/login");
const adminRouter = require("./app/routers/admin");
const client = require("./app/config/redis");
// const adminRouter = require("./app/routers/admin");

app.use("/",  loginRouter);
app.use("/admin", middleware.verify, adminRouter);
// app.use("/admin", adminRouter);

(async () => {
  await redisClient.connect(
    process.env.REDIS_PORT,
    process.env.REDIS_HOST,
    process.env.REDIS_PASS
  );
  // await redisClient.connect(process.env.REDIS_PORT, process.env.REDIS_HOST, process.env.REDIS_PASS);
  //  await client.connect()
   app.listen(process.env.PORT, function () {
    console.log(
      `Node app is listening at http://localhost:` + process.env.PORT
    );
    //process.send("ready");
  });
})()





app.use('/currency', function(req, res, next){
  console.log('REQ:::::', req.body)
  currencyConverter(req.body.currencyFrom, req.body.currencyTo, req.body.amount)
  .then(result=>{
    console.log('RESULT:::::::::::::', result)
    res.status(200).json({
      amount: result
    })
  })
})


