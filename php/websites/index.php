<!DOCTYPE html>
<html>
    <head>
        <title>PHP Test</title>
    </head>
    <body>

    <?php
        $servername = "db";
        $username = "user";
        $password = "password";

        try {
            $conn = new PDO("mysql:host=$servername;dbname=comp3004", $username, $password);
            $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

            $stmt = $conn->prepare("SELECT count FROM counter WHERE id = 1");
            $stmt->execute();

            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            $count = $row['count'];
            $count++;

            $stmt = $conn->prepare("UPDATE counter SET count = :newCount WHERE id = 1");

            $stmt->bindParam(':newCount',  $count);
            $stmt->execute();
        } catch(PDOException $e) {
            echo "Connection failed: " . $e->getMessage();
        }

        echo "<p>This site has been viewed $count times</p>"; 
     ?>
    </body>
</html>