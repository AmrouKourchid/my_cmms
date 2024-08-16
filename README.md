**Building From Source**

1- download and install Node from https://nodejs.org/en/download/prebuilt-installer/current

2- download and install MySQL Community Server from https://dev.mysql.com/downloads/mysql/

2.1- For extra info on installing and configuring MySQL community server/Workbench, follow this guide: https://www.youtube.com/watch?v=u96rVINbAUI

3- Download and install flutter from https://docs.flutter.dev/get-started/install?gad_source=1&gclid=CjwKCAjw8fu1BhBsEiwAwDrsjDACRysW043pP2PCJ3Y3onjdDmTCPU86rJwBYrL6Yt5VqqrPmcvjQBoCX64QAvD_BwE&gclsrc=aw.ds

4- Fork The Repo and clone it using git clone 

5-Open the cloned repo with VScode, inside you will find a file named **cmms.sql** under `lib\data\cmms.sql`

6-Copy and Paste the contents of that file into your MySQL workbench and run it.

7-You Should Now Have a database under your connection called CMMS

8- In MySQL Workbench, Right click on your connection and click on "edit connection"

9- You should change your default schema to cmms like seen in the image:
![image](https://github.com/user-attachments/assets/39ce5bf5-38a5-46fa-81f2-e6ef79cfa9b4)

**Note: you can change other fields to match the image for ease of use later**

10-In `Server.js` located in `\lib\login_server\server.js`, edit the fields in the image below so they match what you inputted in MySQL Workbench:

![image](https://github.com/user-attachments/assets/497866b5-f672-44f0-a0cb-e6eb1b19b019)

11- Open Two Terminals inside your project in VSCode

  11.1- in the first one, navigate to `\lib\login_server\` and run  
  ```
 npm install
 node server.js
 
```

after that, you should get the output : "Server Running on Port 5506, Connected to database"

  11.2- in the Second one, run "flutter run", which should give you a list of connected devices. 

**Important: this app is intended to run on Android, however, it can run and be tested on either windows and/or Web for easier testing/debugging. If you intend to test it on phone, skip to step 14**
  
  12- the app should open and you will get this login screen:

  ![image](https://github.com/user-attachments/assets/c7660f7a-63e3-4054-8e65-550a2940bafc)

  by default, there is only one user in the database that can log in, the admin:
  
  **Email: admin@discovery.com**
  
  **Password: 123**

  13-login and enjoy!

  




 **For People Who want to test this on Android:**

 14-make sure you do all the steps from 1-10. However, instead of using VSCode, you should use Android Studio.

 15- open your cmd on windows and type ipconfig, and copy your IPv4 adress

 16-Open your cloned repo's folder in Android Studio

 17-search for `localhost`, and in any dart (.dart files), replace the `localhost` with your IPv4 adress

 18-open a terminal and navigate to `your_project\lib\login_server\` and run 

 ```
 npm install
 node server.js
 
```
 after that, you should get "Server running on port 5506, connected to database",

 19-Launch your Virtual Device

 20- Run the app using this button: 
 
 ![image](https://github.com/user-attachments/assets/5321ef84-e018-4847-bf9b-f8578742fe8a)

 21- Repeat steps 12 and 13 and enjoy!

  

  

  




