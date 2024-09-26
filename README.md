![image](https://github.com/user-attachments/assets/1807775e-c60f-403b-be2b-f925d252890d)
# Volunteer Matching System

## General Description

Create a database and define usage to support the
matching of Red Cross Volunteer Capacity (supply) with “Local Multidimensional
Vulnerabilities and Crises” (demand). 


## Technology
- Python (Pandas, NumPy)
- PostgresSQL

## UML Diagram

<p align="center">
  <img src="https://github.com/nguyenvuminhh/volunteer-analysis/assets/1807775e-c60f-403b-be2b-f925d252890d">
</p>

## Relational Schema
- Beneficiary(id, name, address, city_id)
- Request(id, beneficiary_id, number_of_volunteers, priority_value, start_date,
end_date, register_by_date)
- Skill(name, description)
- Interest(name)
- Volunteer(id, birthdate, city_id, name, email, address, travel_readiness)
- Volunteer_application(id, request_id, volunteer_id, modified, is_valid)
- City(name, id, geolocation)
- Request_skill(request_id, skill_name, min_need, value)
- Skill_assignment(volunteer_id, skill_name)
- Volunteer_range(volunteer_id, city_id)
- Interest_assignment(interest_name, volunteer_id)
- Request_location(Request_id, city_id)

## Acknowledgement

- This is a group project that was done with the instruction of the professor and teaching assistants of the course _CS-A1155 - Databases for Data Science_ at Aalto University

