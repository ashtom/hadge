#  Your Health Data

This repo is automatically updated by Hadge. If you want to modify the files, create a new branch first. Files in the main branch will be automatically overwritten.

## File Formats

### Activity

The folder `activity` contains activity data from the Activity app. One csv file per year. If you don't use the Apple Watch. there will be no meaningful data in it.

| Column | Description |
| --------- | ------------- |
| Date | The date formatted as yyyy-MM-dd |
| Move Actual | Energy burned in kcal |
| Move Goal | Your personal move goal in kcal |
| Exercise Actual | Number of exercise minutes |
| Exercise Goal | Your personal exercise goal (this cannot be set in iOS, it's always 30min) |
| Stand Actual | Number of stand hours |
| Stand Goal |Your personal stand goal (this cannot be set in iOS, it's always 12h) |

### Distances

The folder `distances` contains distance, walking and running steps, and swimming strokes data. One csv file per year.  

| Column | Description |
| --------- | ------------- |
| Date | The date formatted as yyyy-MM-dd |
| Distance Walking/Running | In meters |
| Steps | Step count for the given date |
| Distance Swimming | In meters |
| Strokes | Stroke count for all swimming workouts on this date |
| Distance Cycling | In meters |
| Distance Wheelchair | In meters |
| Distance Downhill Snowsports | In meters |

### Workouts

The folder `workouts` contains the data for all your workouts. One csv file per year.  

| Column | Description |
| --------- | ------------- |
| UUID | A unique identifier |
| Start Date | Start date/time of the workout, formatted as ISO 8601 (yyyy-MM-dd'T'HH:mm:ssZ) |
| End Date | End date/time of the workout, formatted as ISO 8601 (yyyy-MM-dd'T'HH:mm:ssZ) |
| Type | Workout type as an integer, for example 52 |
| Name | Workout type as string, for example Walking |
| Duration | In seconds |
| Distance | In meters |
| Elevation Ascended | In meters |
| Flights Climbed | Number of flights taken during the workout |
| Swim Strokes | Stroke count for swimming workouts |
| Total Energy | In kcal |

