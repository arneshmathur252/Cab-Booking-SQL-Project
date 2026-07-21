
Create database cab_booking

-- Customers Table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15) UNIQUE NOT NULL,
    Email NVARCHAR(100) UNIQUE,
    RegistrationDate DATE DEFAULT GETDATE()
);
 
-- Drivers Table
CREATE TABLE Drivers (
    DriverID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Phone VARCHAR(15) UNIQUE NOT NULL,
    LicenseNumber VARCHAR(50) UNIQUE NOT NULL,
    Rating DECIMAL(3,2) CHECK (Rating BETWEEN 0 AND 5)
);

-- Cabs Table
CREATE TABLE Cabs (
    CabID INT PRIMARY KEY IDENTITY(1,1),
    CabNumber VARCHAR(20) UNIQUE NOT NULL,
    CabModel NVARCHAR(50),
    CabType NVARCHAR(20) CHECK (CabType IN ('Mini', 'Sedan', 'SUV', 'Luxury')),
    DriverID INT UNIQUE,
    FOREIGN KEY (DriverID) REFERENCES Drivers(DriverID)
);

-- Bookings Table
CREATE TABLE Bookings (
    BookingID INT PRIMARY KEY IDENTITY(1,1),
    CustomerID INT NOT NULL,
    CabID INT NOT NULL,
    BookingDate DATETIME DEFAULT GETDATE(),
    PickupLocation NVARCHAR(200) NOT NULL,
    DropLocation NVARCHAR(200) NOT NULL,
    Status NVARCHAR(20) CHECK (Status IN ('Booked', 'Ongoing', 'Completed', 'Cancelled')) DEFAULT 'Booked',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (CabID) REFERENCES Cabs(CabID)
);

-- Trip Details Table
CREATE TABLE TripDetails (
    TripID INT PRIMARY KEY IDENTITY(1,1),
    BookingID INT UNIQUE NOT NULL,
    TripStartTime DATETIME,
    TripEndTime DATETIME,
    DistanceKM DECIMAL(5,2),
    Fare DECIMAL(10,2),
    FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID)
);

-- Feedback Table
CREATE TABLE Feedback (
    FeedbackID INT PRIMARY KEY IDENTITY(1,1),
    BookingID INT NOT NULL,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    Comments NVARCHAR(500),
    FeedbackDate DATE DEFAULT GETDATE(),
    FOREIGN KEY (BookingID) REFERENCES Bookings(BookingID)
);
-- Customers
INSERT INTO Customers (Name, Phone, Email) VALUES
('Amit Sharma', '9876543210', 'amit@example.com'),
('Priya Singh', '9123456780', 'priya@example.com'),
('Rahul Verma', '9988776655', 'rahul@example.com');

-- Drivers
INSERT INTO Drivers (Name, Phone, LicenseNumber, Rating) VALUES
('Suresh Kumar', '9898989898', 'DL-1234', 4.5),
('Anil Mehta', '9797979797', 'DL-5678', 4.2),
('Vikram Chauhan', '9696969696', 'DL-9101', 4.8);

-- Cabs
INSERT INTO Cabs (CabNumber, CabModel, CabType, DriverID) VALUES
('UP14AB1234', 'Hyundai i10', 'Mini', 1),
('DL8CAF5678', 'Honda City', 'Sedan', 2),
('HR26CD9101', 'Toyota Innova', 'SUV', 3);

-- Bookings
INSERT INTO Bookings (CustomerID, CabID, PickupLocation, DropLocation, Status) VALUES
(1, 1, 'Noida Sector 15', 'Connaught Place', 'Completed'),
(2, 2, 'Saket', 'Gurgaon Cyber City', 'Ongoing'),
(3, 3, 'Dwarka', 'IGI Airport', 'Booked');

-- Trip Details
INSERT INTO TripDetails (BookingID, TripStartTime, TripEndTime, DistanceKM, Fare) VALUES
(1, '2025-08-10 10:00', '2025-08-10 10:45', 15.5, 350.00),
(2, '2025-08-12 09:30', NULL, 8.0, NULL);

-- Feedback
INSERT INTO Feedback (BookingID, Rating, Comments) VALUES
(1, 5, 'Very good service.');

--1View all bookings with customer & driver details
SELECT b.BookingID, c.Name AS CustomerName, d.Name AS DriverName, cb.CabType,
       b.PickupLocation, b.DropLocation, b.Status, td.Fare
FROM Bookings b
JOIN Customers c ON b.CustomerID = c.CustomerID
JOIN Cabs cb ON b.CabID = cb.CabID
JOIN Drivers d ON cb.DriverID = d.DriverID
LEFT JOIN TripDetails td ON b.BookingID = td.BookingID;

--2 Find top-rated drivers
SELECT Name, Rating 
FROM Drivers
WHERE Rating >= 4.5;

--3 Get total revenue
SELECT SUM(Fare) AS TotalRevenue
FROM TripDetails
WHERE Fare IS NOT NULL;

--4List all ongoing trips
SELECT b.BookingID, c.Name, cb.CabNumber, td.DistanceKM
FROM Bookings b
JOIN Customers c ON b.CustomerID = c.CustomerID
JOIN Cabs cb ON b.CabID = cb.CabID
LEFT JOIN TripDetails td ON b.BookingID = td.BookingID
WHERE b.Status = 'Ongoing';
-----------------------------
-- 5. Cancelled booking percentage
-----------------------------
SELECT 
    (CAST(SUM(CASE WHEN Status = 'Cancelled' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*)) * 100 AS CancelledPercentage
FROM Bookings;

-----------------------------
-- 6. Longest trip by distance
-----------------------------
SELECT TOP 1 
    td.TripID, td.DistanceKM
FROM TripDetails td
ORDER BY td.DistanceKM DESC;

-----------------------------
-- 7. Average trip duration in minutes
-----------------------------
SELECT 
    AVG(DATEDIFF(MINUTE, TripStartTime, TripEndTime)) AS AvgTripMinutes
FROM TripDetails
WHERE TripStartTime IS NOT NULL AND TripEndTime IS NOT NULL;

-----------------------------
-- 8. Most popular pickup location
-----------------------------
SELECT TOP 1 PickupLocation, COUNT(*) AS TotalPickups
FROM Bookings
GROUP BY PickupLocation
ORDER BY TotalPickups DESC;

----------------------------
-- 9. Average Fare by Cab Type
----------------------------
SELECT cb.CabType, AVG(td.Fare) AS AvgFare
FROM TripDetails td
JOIN Bookings b ON td.BookingID = b.BookingID
JOIN Cabs cb ON b.CabID = cb.CabID
GROUP BY cb.CabType;
-----------------------------
--10. Number of Trips per Driver
-----------------------------
SELECT d.Name AS DriverName, COUNT(td.TripID) AS TripsCount
FROM Drivers d
JOIN Cabs cb ON d.DriverID = cb.DriverID
JOIN Bookings b ON cb.CabID = b.CabID
JOIN TripDetails td ON b.BookingID = td.BookingID
WHERE td.TripEndTime IS NOT NULL
GROUP BY d.Name;
------------------------------
--11. Most Frequent Customer
------------------------------
SELECT c.Name AS CustomerName, COUNT(*) AS BookingCount
FROM Customers c
JOIN Bookings b ON c.CustomerID = b.CustomerID
GROUP BY c.Name
ORDER BY BookingCount DESC
OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY;
-------------------------------
--12. Average Rating per Driver
-------------------------------
SELECT d.Name AS DriverName, AVG(f.Rating) AS AvgFeedbackRating
FROM Drivers d
JOIN Cabs cb ON d.DriverID = cb.DriverID
JOIN Bookings b ON cb.CabID = b.CabID
JOIN Feedback f ON b.BookingID = f.BookingID
GROUP BY d.Name;
-------------------------------
--13. Bookings per Day
-------------------------------
SELECT CAST(BookingDate AS DATE) AS BookingDay, COUNT(*) AS TotalBookings
FROM Bookings
GROUP BY CAST(BookingDate AS DATE)
ORDER BY BookingDay;
-------------------------------
--14. Bookings with No Trip Yet
-------------------------------
SELECT b.BookingID, c.Name AS CustomerName, b.Status
FROM Bookings b
JOIN Customers c ON b.CustomerID = c.CustomerID
LEFT JOIN TripDetails td ON b.BookingID = td.BookingID
WHERE td.TripID IS NULL;
-------------------------------
--15. Trips Longer Than 10 km
-------------------------------
SELECT td.TripID, td.DistanceKM, b.BookingID
FROM TripDetails td
JOIN Bookings b ON td.BookingID = b.BookingID
WHERE td.DistanceKM > 10;
-------------------------------
--16. Total Distance Covered by Each Cab
-------------------------------
SELECT cb.CabNumber, SUM(td.DistanceKM) AS TotalDistance
FROM Cabs cb
JOIN Bookings b ON cb.CabID = b.CabID
JOIN TripDetails td ON b.BookingID = td.BookingID
GROUP BY cb.CabNumber;
-------------------------------
--17. Feedback Count per Booking
-------------------------------
SELECT b.BookingID, COUNT(f.FeedbackID) AS FeedbackCount
FROM Bookings b
LEFT JOIN Feedback f ON b.BookingID = f.BookingID
GROUP BY b.BookingID;
--------------------------------
--18. Drivers Without Completed Trips
--------------------------------
SELECT d.Name AS DriverName
FROM Drivers d
JOIN Cabs cb ON d.DriverID = cb.DriverID
LEFT JOIN Bookings b ON cb.CabID = b.CabID AND b.Status = 'Completed'
WHERE b.BookingID IS NULL;
--------------------------------
--19. Revenue by Day
--------------------------------
SELECT CAST(td.TripStartTime AS DATE) AS TripDay, SUM(td.Fare) AS Revenue
FROM TripDetails td
WHERE td.Fare IS NOT NULL
GROUP BY CAST(td.TripStartTime AS DATE)
ORDER BY TripDay;
--------------------------------
--20. Average Trip Speed (if fare and some per‑km average is known, or use distance/time)
--------------------------------
SELECT td.TripID,
       td.DistanceKM / (DATEDIFF(MINUTE, td.TripStartTime, td.TripEndTime) / 60.0) AS AvgSpeedKMPH
FROM TripDetails td
WHERE td.TripStartTime IS NOT NULL AND td.TripEndTime IS NOT NULL AND td.DistanceKM > 0;
-------------------------------
--21. List customers who have never given feedback
------------------------------
SELECT c.Name
FROM Customers c
JOIN Bookings b ON c.CustomerID = b.CustomerID
LEFT JOIN Feedback f ON b.BookingID = f.BookingID
WHERE f.FeedbackID IS NULL
GROUP BY c.Name;
------------------------------
--22. List drivers with more than 2 bookings
------------------------------
SELECT d.Name, COUNT(*) AS TotalBookings
FROM Drivers d
JOIN Cabs cb ON d.DriverID = cb.DriverID
JOIN Bookings b ON cb.CabID = b.CabID
GROUP BY d.Name
HAVING COUNT(*) > 2;
------------------------------
--23. Find average rating for each cab model
-----------------------------
SELECT cb.CabModel, AVG(f.Rating) AS AvgRating
FROM Cabs cb
JOIN Bookings b ON cb.CabID = b.CabID
JOIN Feedback f ON b.BookingID = f.BookingID
GROUP BY cb.CabModel;
-----------------------------
--24. Get drivers who have driven for multiple customers
-----------------------------
SELECT d.Name, COUNT(DISTINCT b.CustomerID) AS UniqueCustomers
FROM Drivers d
JOIN Cabs cb ON d.DriverID = cb.DriverID
JOIN Bookings b ON cb.CabID = b.CabID
GROUP BY d.Name
HAVING COUNT(DISTINCT b.CustomerID) > 1;
-----------------------------
--25. Find the customer with the highest single fare
-----------------------------
SELECT TOP 1 c.Name, td.Fare
FROM Customers c
JOIN Bookings b ON c.CustomerID = b.CustomerID
JOIN TripDetails td ON b.BookingID = td.BookingID
ORDER BY td.Fare DESC;
---------------------------
--26. Find trips with missing fare but completed status
--------------------------
SELECT b.BookingID, td.TripID
FROM Bookings b
JOIN TripDetails td ON b.BookingID = td.BookingID
WHERE b.Status = 'Completed' AND td.Fare IS NULL;
--------------------------
--27. Show how many times each cab was booked
--------------------------
SELECT cb.CabNumber, COUNT(b.BookingID) AS BookingCount
FROM Cabs cb
LEFT JOIN Bookings b ON cb.CabID = b.CabID
GROUP BY cb.CabNumber;
--------------------------
--28. Get all trips longer than 45 minutes
--------------------------
SELECT td.TripID, b.BookingID, DATEDIFF(MINUTE, td.TripStartTime, td.TripEndTime) AS DurationMin
FROM TripDetails td
JOIN Bookings b ON td.BookingID = b.BookingID
WHERE TripStartTime IS NOT NULL AND TripEndTime IS NOT NULL
  AND DATEDIFF(MINUTE, td.TripStartTime, td.TripEndTime) > 45;
  -----------------------
  --29. List all customers registered in the last 30 days
  ----------------------
  SELECT CustomerID, Name, RegistrationDate
FROM Customers
WHERE RegistrationDate >= DATEADD(DAY, -30, GETDATE());
-------------------------
--30. Find drivers who haven’t received any feedback
-------------------------
SELECT d.Name
FROM Drivers d
JOIN Cabs cb ON d.DriverID = cb.DriverID
JOIN Bookings b ON cb.CabID = b.CabID
LEFT JOIN Feedback f ON b.BookingID = f.BookingID
WHERE f.FeedbackID IS NULL
GROUP BY d.Name;
------------------------
--31. Show average number of bookings per customer
------------------------
SELECT AVG(BookingCount) AS AvgBookingsPerCustomer
FROM (
    SELECT CustomerID, COUNT(*) AS BookingCount
    FROM Bookings
    GROUP BY CustomerID
) AS CustomerBookings;
------------------------
--32. Identify idle drivers (drivers with no bookings)
------------------------
SELECT d.Name
FROM Drivers d
LEFT JOIN Cabs cb ON d.DriverID = cb.DriverID
LEFT JOIN Bookings b ON cb.CabID = b.CabID
WHERE b.BookingID IS NULL;
-------------------------
--33Categorize trips by fare range
-------------------------
SELECT TripID, Fare,
    CASE 
        WHEN Fare < 200 THEN 'Low Fare'
        WHEN Fare BETWEEN 200 AND 500 THEN 'Medium Fare'
        ELSE 'High Fare'
    END AS FareCategory
FROM TripDetails
WHERE Fare IS NOT NULL;
-----------------------
--34. Get the cab(s) with the highest number of bookings
-----------------------
SELECT CabID, COUNT(*) AS BookingCount
FROM Bookings
GROUP BY CabID
HAVING COUNT(*) = (
    SELECT MAX(BookingFrequency)
    FROM (
        SELECT COUNT(*) AS BookingFrequency
        FROM Bookings
        GROUP BY CabID
    ) AS CabCounts
);
-------------------------
--35Mark bookings as 'In Progress' or 'Finished'
-------------------------
SELECT BookingID, Status,
    CASE 
        WHEN Status IN ('Booked', 'Ongoing') THEN 'In Progress'
        ELSE 'Finished'
    END AS BookingStage
FROM Bookings;
-------------------------
--36. Find bookings with the highest fare
-------------------------
SELECT BookingID, Fare
FROM TripDetails
WHERE Fare = (
    SELECT MAX(Fare) FROM TripDetails
);
--------------------------
--37.Show customer feedback sentiment based on rating
--------------------------
SELECT f.BookingID, f.Rating,
    CASE 
        WHEN f.Rating = 5 THEN 'Excellent'
        WHEN f.Rating = 4 THEN 'Good'
        WHEN f.Rating = 3 THEN 'Average'
        WHEN f.Rating <= 2 THEN 'Poor'
        ELSE 'No Rating'
    END AS FeedbackSentiment
FROM Feedback f;
-------------------------
--38.Identify long or short trips based on duration
------------------------
SELECT TripID,
    DATEDIFF(MINUTE, TripStartTime, TripEndTime) AS DurationMinutes,
    CASE 
        WHEN DATEDIFF(MINUTE, TripStartTime, TripEndTime) > 45 THEN 'Long Trip'
        ELSE 'Short Trip'
    END AS TripLength
FROM TripDetails
WHERE TripStartTime IS NOT NULL AND TripEndTime IS NOT NULL;
------------------------
--39. Get drivers who received only 5-star feedback
------------------------
SELECT d.Name
FROM Drivers d
WHERE d.DriverID IN (
    SELECT cb.DriverID
    FROM Cabs cb
    JOIN Bookings b ON cb.CabID = b.CabID
    WHERE b.BookingID NOT IN (
        SELECT BookingID FROM Feedback WHERE Rating < 5
    )
);
------------------------
--40.Assign a discount tag based on fare
------------------------
SELECT TripID, Fare,
    CASE 
        WHEN Fare >= 1000 THEN 'Eligible for 20% Discount'
        WHEN Fare >= 500 THEN 'Eligible for 10% Discount'
        ELSE 'No Discount'
    END AS DiscountTag
FROM TripDetails
WHERE Fare IS NOT NULL;
--------------------------
--41.Label cabs based on type
--------------------------
SELECT CabID, CabNumber, CabType,
    CASE 
        WHEN CabType = 'Luxury' THEN 'Premium Service'
        WHEN CabType = 'SUV' THEN 'Family Ride'
        WHEN CabType = 'Sedan' THEN 'Comfort Ride'
        ELSE 'Budget Ride'
    END AS ServiceLabel
FROM Cabs;
----------------------------
--42.Determine if a driver is experienced (rating ≥ 4.5)
----------------------------
SELECT Name, Rating,
    CASE 
        WHEN Rating >= 4.5 THEN 'Experienced'
        ELSE 'Regular'
    END AS ExperienceLevel
FROM Drivers;
----------------------------
--43. Show feedback rating with color codes
----------------------------
SELECT Rating,

    CASE 

        WHEN Rating = 5 THEN 'Green'

        WHEN Rating = 4 THEN 'Blue'

        WHEN Rating = 3 THEN 'Yellow'

        WHEN Rating <= 2 THEN 'Red'

        ELSE 'Gray'

    END AS ColorCode

FROM Feedback;
-----------------------------
--44. List top 3 customers by total fare spent using subquery
-----------------------------
SELECT TOP 3 CustomerID, TotalSpent
FROM (
    SELECT b.CustomerID, SUM(td.Fare) AS TotalSpent
    FROM Bookings b
    JOIN TripDetails td ON b.BookingID = td.BookingID
    GROUP BY b.CustomerID
) AS FareSummary
ORDER BY TotalSpent DESC;
------------------------------
--45. Get customer names in uppercase
------------------------------
SELECT UPPER(Name) AS UpperCaseName
FROM Customers;
------------------------------
--46.Determine customer activity status based on booking count
------------------------------
SELECT c.CustomerID, c.Name,
    CASE 
        WHEN COUNT(b.BookingID) >= 5 THEN 'Frequent Rider'
        WHEN COUNT(b.BookingID) BETWEEN 2 AND 4 THEN 'Returning Rider'
        ELSE 'New Customer'
    END AS RiderType
FROM Customers c
LEFT JOIN Bookings b ON c.CustomerID = b.CustomerID
GROUP BY c.CustomerID, c.Name;
------------------------------
--47. List drivers whose names start with 'A'
------------------------------
SELECT Name
FROM Drivers
WHERE LEFT(Name, 1) = 'A';
------------------------------
--48. Extract the area code (first 4 characters) from cab numbers
------------------------------
SELECT CabNumber, SUBSTRING(CabNumber, 1, 4) AS AreaCode
FROM Cabs;
------------------------------
--49. Replace 'Sector' with 'Sec' in pickup locations
------------------------------
SELECT PickupLocation, REPLACE(PickupLocation, 'Sector', 'Sec') AS ShortPickup
FROM Bookings;
------------------------------
--50. Show length of each customer’s name
------------------------------
SELECT Name, LEN(Name) AS NameLength
FROM Customers;
------------------------------
--51. Count of total bookings per status
------------------------------
SELECT Status, COUNT(*) AS Total
FROM Bookings
GROUP BY Status;
------------------------------
--52. Maximum fare collected in a single trip
------------------------------
SELECT MAX(Fare) AS MaxFare
FROM TripDetails;
-----------------------------
--53. Minimum and average rating given in feedback
-----------------------------
SELECT MIN(Rating) AS MinRating, AVG(Rating) AS AvgRating
FROM Feedback;
----------------------------
--54. Count of customers who have given feedback
---------------------------
SELECT COUNT(DISTINCT b.CustomerID) AS FeedbackGivers
FROM Bookings b
JOIN Feedback f ON b.BookingID = f.BookingID;
---------------------------
--55. Total distance covered by all cabs
--------------------------
SELECT SUM(DistanceKM) AS TotalDistance
FROM TripDetails;
-------------------------
--56. Average fare per cab type
------------------------
SELECT cb.CabType, AVG(td.Fare) AS AvgFare
FROM Cabs cb
JOIN Bookings b ON cb.CabID = b.CabID
JOIN TripDetails td ON b.BookingID = td.BookingID
GROUP BY cb.CabType;
-------------------------
--57. Convert fare to integer value (remove decimal)
-------------------------
SELECT TripID, Fare, CAST(Fare AS INT) AS FareAsInteger
FROM TripDetails;
------------------------
--58. Convert booking date to YYYY-MM-DD string format
------------------------
SELECT BookingID, CONVERT(VARCHAR(10), BookingDate, 120) AS BookingDateFormatted
FROM Bookings;
-----------------------
--59. Try casting customer phone number to BIGINT
----------------------
SELECT Name, Phone, TRY_CAST(Phone AS BIGINT) AS PhoneNumeric
FROM Customers;
----------------------
--60. Convert trip duration from minutes to decimal hours
----------------------
SELECT TripID,
       DATEDIFF(MINUTE, TripStartTime, TripEndTime) AS DurationMin,
       CAST(DATEDIFF(MINUTE, TripStartTime, TripEndTime) AS DECIMAL(5,2)) / 60 AS DurationHours
FROM TripDetails
WHERE TripStartTime IS NOT NULL AND TripEndTime IS NOT NULL;









