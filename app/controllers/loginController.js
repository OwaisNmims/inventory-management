const Login = require('../models/admin/login');
const bcrypt = require("bcrypt");
const DeviceDetector = require("device-detector-js");
const deviceDetector = new DeviceDetector();
const {
  redisClient
} = require("../utils/redisClient");

module.exports = {
    login: async function (req, res) {
    //   let token = req.cookies.token;
      if (req.method == "GET") {
  
        try {
          console.log('ikde aalaaa')
            
            res.render("login.ejs")
        } catch (error) {
            res.render("admin/error.ejs")
        //   errorResponse(req, null, error.message, 500, error);
        //   successRender(null, res, "login.ejs", {
        //     public_key: public_key
        //   });
        }
      }
    },
    
  Authenticate: async (req, res, next) => {
    
    let token = req.cookies.token;
    console.log('token:::::::::', req.cookies)
    let {
      email,
      password
    } = {
      ...req.body,
      ...req.params,
      ...req.query,
    };

    Login.findOneForLogin(email).then( async (data) => {
      let result = data.rows[0];
      console.log('result::::::::::::::', result)
      if (result != null || typeof result != "undefined") {
        if (bcrypt.compareSync(password, result.password)) {

          let user = {};
          user.firstname = result.firstname;
          user.lastname = result.lastname;
          user.id = result.id
          user.email = result.email;
          delete result.password;

          redisClient.client.set(
            token,
            JSON.stringify(user),
            async function (err, response) {
              if (err) {
                console.log(err);
                res.status(500).json({
                  msg: "something went wrong...try again later",
                });
              } else {
                let resp = await response;
                console.log("resp redis write ==> ", resp);
                redisClient.client.expire(token, process.env.REDIS_TTL);
                  let redirect = "";
                  redirect = "/admin/dashboard";
                  res.status(200).json({
                    status: "SUCCESS",
                    redirect: redirect,
                  });
                
              }
            }
          );
         
        } else {
           res.status(401).json({
            msg: "unauthorised access...password did not match",
          });
        }
      } else {
        res.status(404).json({
          msg: "invalid user...no such user",
        });
      }
    });
  }
}

