import 'dotenv/config';
import express from "express";
import bodyParser from "body-parser";
import pg from "pg";
import ejs from "ejs";
import {dirname} from "path" ;
import {fileURLToPath} from "url";
import session from "express-session";
const bcryptjs = await import('bcryptjs');
const bcrypt = bcryptjs.default;
import passport from "passport";
import { Strategy } from "passport-local";
import path from "path";

const app = new express();
const port = process.env.PORT || 3000;
const saltRounds=10;

app.use(session({
  secret: 'secret',
  resave: false,
  saveUninitialized: true,
// Use true in production with HTTPS
}));

app.use(express.static("public"));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());

app.use(passport.initialize());
app.use(passport.session());

const __dirname= dirname(fileURLToPath(import.meta.url));
console.log(__dirname);
app.set('views', path.join(__dirname, 'views'));
app.use(express.static(path.join(__dirname, '../frontend/public')));

// Set the view engine to EJS
app.set('view engine', 'ejs');
const db = new pg.Client({
   user:process.env.DBUSER || "postgres",
   host:process.env.DBHOST || "localhost",
   database:process.env.DBDATABASE|| "world",
   password:process.env.DBPASSWORD|| "191023",
   port:process.env.DBPORT||5432
});
db.connect();
//To get all task 
async function getTaskList(){
    const task_detail= await db.query("SELECT * FROM gettask($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)"[user.id,user.email,0,NULL,NULL,NULL,NULL,NULL,NULL,0]);
    return task_detail;
}
async function getAllTaskList(req,res){
    const resultSet= await getTaskList(); 
    if(resultSet.rowCount){
     res.render("activity.ejs",{
        tasksList:resultSet.rows,
        count:1,
        userId:req.session.user
     });
    }
    else {
        res.render("activity.ejs",{
            count:0,
            tasksList:'No task added , Add now',
            userId:req.session.user
         }); 
    }
}

async function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0'); // Months are 0-indexed
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}
 
app.get("/",(req,res)=>{
    res.render("index");
});
app.get("/performance",(req,res)=>{
  res.render("performance");
});
app.get("/login",(req,res)=>{
    res.render("login");
});
app.get("/signup",(req,res)=>{
    res.render("signup");
})

app.get("/logout", (req, res) => {
    req.logout(function (err) {
      if (err) {
        return next(err);
      }
      res.redirect("/");
    });
  });

app.post('/delete-task', async (req, res) => {
  if (req.isAuthenticated()) {
    const {taskId} = req.body; 
    const parsedTaskIds = taskId.map(id => parseInt(id, 10)).map(id => parseInt(id, 10));
    const placeholders = parsedTaskIds.map((_, index) => `$${index + 2}`).join(', ');
    const query =`UPDATE tasks SET deleted = ($1) where task_id IN (${placeholders})`;
    const values = [1, ...parsedTaskIds];
    const result = await db.query(query, values);
    if (result) {
      res.status(200).send({ message: 'Task deleted successfully' });
    } else {
      res.status(404).send({ message: 'Task not found' });
    }
  }
  else{
    res.redirect("/login");
  }
});
app.get("/dashboard/today", async (req,res) =>{
    if (req.isAuthenticated()) {
      const currentDate = await formatDate(new Date());
      
      const task_detail=  await db.query("SELECT * FROM gettask($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)",[req.user.id,req.user.email,0,null,null,null,null,currentDate,currentDate,null,0,null,null]);
      const resultSet =  task_detail;
   
      if(resultSet.rowCount){
        res.render("activity",{
           tasksList:resultSet.rows,
           count:1,
           section:'today',
           userId:req.user.email
        });
       }
       else {
           res.render("activity",{
               count:0,
               tasksList:'Wow,You finished all tasks 🎉🥳',
               section:'today',
               userId:req.user.email
            }); 
       }
      } else {
        res.redirect("/login");
      }
      
   
});

app.get("/dashboard/upcoming", async (req,res) =>{
  if (req.isAuthenticated()) {
    var currentDate = new Date();
    currentDate.setDate(currentDate.getDate()+1);
   const formattedcurrentdate =await formatDate(currentDate) ;
    var upcomingDate = new Date();
    upcomingDate.setDate(upcomingDate.getDate()+365);
    const formattedupcomingdate =await formatDate(upcomingDate) ;
    console.log(formattedupcomingdate);
    console.log(formattedcurrentdate);
    const task_detail=  await db.query("SELECT * FROM gettask($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)",[req.user.id,req.user.email,0,null,null,null,null,formattedcurrentdate,formattedupcomingdate,null,0,null,null]);
    const resultSet =  task_detail;
 
    if(resultSet.rowCount){
      res.render("activity",{
         tasksList:resultSet.rows,
         count:1,
         section:'upcoming',
         userId:req.user.email
      });
     }
     else {
         res.render("activity",{
             count:0,
             tasksList:'No upcoming tasks,Add now?🤔',
             section:'upcoming',
             userId:req.user.email
          }); 
     }
    } else {
      res.redirect("/login");
    }
    
 
});

app.get("/dashboard/finished", async (req,res) =>{
  if (req.isAuthenticated()) {
    const task_detail=  await db.query("SELECT * FROM gettask($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)",[req.user.id,req.user.email,0,null,null,null,null,null,null,'Done',0,null,null]);
    const resultSet =  task_detail;
 
    if(resultSet.rowCount){
      res.render("activity",{
         tasksList:resultSet.rows,
         count:1,
         section:'finished',
         userId:req.user.email
      });
     }
     else {
         res.render("activity",{
             count:0,
             tasksList:'Finish your first task soon 🎯',
             section:'upcoming',
             userId:req.user.email
          }); 
     }
    } else {
      res.redirect("/login");
    }
    
 
});

app.get("/dashboard/due", async (req,res) =>{
  if (req.isAuthenticated()) {
    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    var formattedyesterday = await formatDate(yesterday);
    const previousyear = new Date();
    previousyear.setDate(yesterday.getDate() - 365);
    var formattedyear= await formatDate(previousyear);
    console.log(formattedyesterday);
    const task_detail=  await db.query("SELECT * FROM gettask($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)",[req.user.id,req.user.email,0,null,null,null,null,formattedyear,formattedyesterday,null,0,null,null]);
    const resultSet =  task_detail;
 
    if(resultSet.rowCount){
      res.render("activity",{
         tasksList:resultSet.rows,
         count:1,
         section:'due',
         userId:req.user.email
      });
     }
     else {
         res.render("activity",{
             count:0,
             tasksList:'Keep it up, No Dues 🥳✨🔥',
             section:'due',
             userId:req.user.email
          }); 
     }
    } else {
      res.redirect("/login");
    }
    
 
});

app.post("/weekTask",(req,res)=>{
    var result = req.body;
    const userId = req.user['id'];
    console.log(req.body);
    var queryresult = db.query(" CALL upserttask($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)",[userId,0,result['activity'],result['description'],result['priority'],0, result['deadline'],result['status'],0,result['impact'],result['reward'],0]);
    res.redirect('/dashboard/today');
    
});

app.post("/taskEdit",(req,res)=>{
    var result = req.body;
    const userId = req.user['id'];
    var queryresult = db.query(" CALL upserttask($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)",[userId,result['task_id'],result['activity'],result['description'],result['priority'],0,result['deadline'],result['status'],0,result['impact'],result['reward'],0]);
    res.redirect('/dashboard/today');
    
});


  app.post("/signup", async (req, res) => {
    const email = req.body.email;
    const name = req.body.name;
    const role = req.body.role;
    const password = req.body.password;
  
    try {
      const checkResult = await db.query("SELECT * FROM users WHERE email = ($1)", [
        email
      ]);
  
      if (checkResult.rows.length > 0) {
        req.redirect("/login");
      } else {
        bcrypt.hash(password, saltRounds, async (err, hash) => {
          if (err) {
            console.error("Error hashing password:", err);
          } else {
            const result = await db.query(
              "INSERT INTO users (email,name,role, password) VALUES ($1, $2,$3,$4) RETURNING *",
              [email,name,role, hash]
            );
            const user = result.rows[0];
            req.login(user, (err) => {
              console.log("success");
              res.redirect("/dashboard/today");
            });
          }
        });
      }
    } catch (err) {
      console.log(err);
    }
  });

  app.post('/logins',passport.authenticate("local", {
    successRedirect: "/dashboard/today",
    failureRedirect: "/login"
}));

  passport.use("local",
    new Strategy({ usernameField: 'email' },async function verify(email, password, cb) {
      try {
       
        const result = await db.query("SELECT * FROM users WHERE email = ($1) ", [
          email
        ]);
       
        if (result.rows.length > 0) {
          const user = result.rows[0];
          const storedHashedPassword = user.password;
          bcrypt.compare(password, storedHashedPassword, (err, valid) => {
            if (err) {
              //Error with password check
              console.error("Error comparing passwords:", err);
              return cb(err);
            } else {
              if (valid) {
                //Passed password check
               
                return cb(null, user);
              } else {
                //Did not pass password check
                return cb(null, false);
              }
            }
          });
        } else {
          return cb("User not found");
        }
      } catch (err) {
        console.log(err);
      }
    })
  );
  
  passport.serializeUser((user, cb) => {
    cb(null, user);
  });
  passport.deserializeUser((user, cb) => {
    cb(null, user);
  });




app.listen(port, (err,res)=>{
    if(err){
        console.log(err)
    }
    else{
        console.log(`Running on ${port}`);
    }
})