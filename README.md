# NextQuest
Version: 3.0 - Dec 10 2024
Team Members: Samman Tyata

NextQuest is a SwiftUI application designed to connect users with lesser-known attractions cherished by locals. The app aims to provide personalized recommendations based on location, offering an authentic travel experience.

## Project Overview

Currently, in the prototype phase, this project focuses on core feature implementation. The app includes functional UI components for:

1. Listing Locations: Users can view a curated list of attractions.
2. Adding New Attractions: Users can contribute by adding new locations.
3. Displaying Detailed Information: Each site features detailed information, including maps and user comments.
4. Review the location: User rates the location and writes a review, optionally adding photos.

Screens have been designed with minimal yet functional buttons to demonstrate navigation and interaction. The current version includes example data for testing purposes, which will be replaced with real user-generated content in future iterations. NextQuest utilizes a Firebase backend for data storage, ensuring efficient management of location data and user contributions.

## Project Timeline Overview
1.	Initial Planning & Setup -- Completed
2.	Core Feature Development -- Completed
3.	Integration, Testing, and Refinement -- Completed
4.	Final Testing, Deployment, and Launch Preparation -- Completed

## Progress Update
1. All the features needed for the MVP are operational.
2. User can sort the locations based on the proximity ot alphabetical order. 
3. Average ratings are now accurately reflected. 
4. Reviews made by a different user can't be edited or deleted. However, if the review is editable by the user who added it. 
5. State management to store the data and views appropriately.
6. Firebase Authentication and data storage is fully operational.
7. Add photos for the spot.
8. Added spot type and updated the list with icon to view the type - outdoor/food. 

## List of features needed for the MVP + Breakdown of tasks

1. List all the Locations added by the Users:
    - Design the UI for listing all user-added locations.
2. Adding a new location
    - Design a UI for users to add a new location, including fields for the name, and address.
    - Set up a database schema for storing location data with relevant fields (name, address, coordinates)
3. Display detailed information (e.g., name, address, map with annotations, images, comments)
    - UI to show detailed information about each location, including:
        - Location name, address, description, and category.
        - Embedded map with an annotation marking the location.
        - A section for user reviews and comments.
    - Set up storage and retrieval for user-uploaded details associated with each location.
4. Rating and Review System: The user rates the location and writes a review, optionally adding
photos
    - Design a rating and review form where users can rate the location, and add comments.
    - Implement an aggregation function to calculate the average rating for each location.
    - Fetch and display all reviews and ratings for a given location from the database.
  
## Mapping between features and value(s) to be delivered by your app (justification)
1. List location -> aligns with the app’s goal of offering authentic local attractions.
2. Adding a new location -> Builds community engagement and content richness, making
the app dynamic and unique.
3. Display Detailed Information -> Improves the user experience by providing all needed
details for each attraction in a single view.
4. Rating and Review System -> Adds credibility and helps users assess attractions based
on peer reviews.

## Challenges Unique to Mobile Devices:
1. GPS sensor is used to get the device's real-time location.
2. External Storage Dependencies - Firebase to store the list of locations with real-time updates of all devices + Firebase for secure authentication with verification.
3. Launching external applications. - Open Apple maps for directions.
