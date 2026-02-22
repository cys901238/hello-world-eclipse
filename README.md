# hello-world-eclipse

Simple Java Maven project (Hello World) created for Eclipse.

How to import into Windows Eclipse:

1. Open Eclipse -> File -> Import -> Existing Maven Projects -> Select the repository folder (D:\\somi-work\\hello-world-eclipse)
2. Wait for Maven dependencies to resolve.
3. Run the application:
   - Run As -> Java Application
   - Main class: com.example.HelloWorld

Or from command line:

mvn package
java -cp target/hello-world-eclipse-0.1.0.jar com.example.HelloWorld

Notes:
- Java 11 is used as target compatibility.
- If you want an Eclipse Run Configuration, import the provided .launch file.
