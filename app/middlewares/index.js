
const { v4: uuidv4 } = require("uuid");
const { redisClient } = require("../utils/redisClient");


exports.verify = function (req, res, next) {
    if (typeof req.cookies.token == "undefined") {
      res.render("login");
    } else {
      redisClient.client.get(req.cookies.token, async function (err, obj) {
        if (err) {
          console.error(err);
          res.status(500).json({
            msg: "something went wrong...try again later",
            error: err
          })
        } else {
          let response = await obj;
          if (response) {
            response = JSON.parse(response);
            req.body._user = {
              id: response.id,
              firstname: response.firstname,
              lastname: response.lastname,
              email: response.email,
            };
            res.locals.id = response.id;
            next();
          } else {
            res.redirect("/login")
          }
        }
      });
    }
  };