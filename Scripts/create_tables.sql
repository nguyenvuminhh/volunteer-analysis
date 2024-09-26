CREATE TABLE City (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    geolocation VARCHAR(255)
);

CREATE TABLE Beneficiary (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    address VARCHAR(255),
    city_id INT,
    FOREIGN KEY (city_id) REFERENCES City(id)
);

CREATE TABLE Request (
    id INT PRIMARY key,
    title TEXT,
    beneficiary_id INT,
    number_of_volunteers INT,
    priority_value INT,
    start_date TIMESTAMP,
    end_date TIMESTAMP,
    register_by_date TIMESTAMP,
    FOREIGN KEY (beneficiary_id) REFERENCES Beneficiary(id)
);

CREATE TABLE Skill (
    name VARCHAR(255) PRIMARY KEY,
    description TEXT
);

CREATE TABLE Interest (
    name VARCHAR(255) PRIMARY KEY
);

CREATE TABLE Volunteer (
    id varchar(15) PRIMARY KEY,
    birthdate DATE,
    city_id INT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    address VARCHAR(255),
    travel_readiness INT,
    FOREIGN KEY (city_id) REFERENCES City(id)
);

CREATE TABLE Volunteer_application (
    id INT PRIMARY KEY,
    request_id INT,
    volunteer_id varchar(15),
    modified TIMESTAMP,
    is_valid BOOLEAN,
    FOREIGN KEY (request_id) REFERENCES Request(id),
    FOREIGN KEY (volunteer_id) REFERENCES Volunteer(id)
);

CREATE TABLE Request_skill (
    request_id INT,
    skill_name VARCHAR(255),
    min_need INT,
    value INT,
    PRIMARY KEY (request_id, skill_name),
    FOREIGN KEY (request_id) REFERENCES Request(id),
    FOREIGN KEY (skill_name) REFERENCES Skill(name)
);

CREATE TABLE Skill_assignment (
    volunteer_id varchar(15),
    skill_name VARCHAR(255),
    PRIMARY KEY (volunteer_id, skill_name),
    FOREIGN KEY (volunteer_id) REFERENCES Volunteer(id),
    FOREIGN KEY (skill_name) REFERENCES Skill(name)
);

CREATE TABLE Volunteer_range (
    volunteer_id varchar(15),
    city_id INT,
    PRIMARY KEY (volunteer_id, city_id),
    FOREIGN KEY (volunteer_id) REFERENCES Volunteer(id),
    FOREIGN KEY (city_id) REFERENCES City(id)
);

CREATE TABLE Interest_assignment (
    interest_name VARCHAR(255),
    volunteer_id varchar(15),
    PRIMARY KEY (interest_name, volunteer_id),
    FOREIGN KEY (interest_name) REFERENCES Interest(name),
    FOREIGN KEY (volunteer_id) REFERENCES Volunteer(id)
);

CREATE TABLE Request_location (
    request_id INT,
    city_id INT,
    PRIMARY KEY (request_id, city_id),
    FOREIGN KEY (request_id) REFERENCES Request(id),
    FOREIGN KEY (city_id) REFERENCES City(id)
);