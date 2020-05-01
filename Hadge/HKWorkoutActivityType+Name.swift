//
//  HKWorkoutActivityType+Name.swift
//  Hadge
//
//  Created by Thomas Dohmke on 4/27/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

// Source: https://stackoverflow.com/a/61140433 and
// https://github.com/georgegreenoflondon/HKWorkoutActivityType-Descriptions/blob/master/HKWorkoutActivityType%2BDescriptions.swift
extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .americanFootball:             return "American Football"
        case .archery:                      return "Archery"
        case .australianFootball:           return "Australian Football"
        case .badminton:                    return "Badminton"
        case .baseball:                     return "Baseball"
        case .basketball:                   return "Basketball"
        case .bowling:                      return "Bowling"
        case .boxing:                       return "Boxing"
        case .climbing:                     return "Climbing"
        case .crossTraining:                return "Cross Training"
        case .curling:                      return "Curling"
        case .cycling:                      return "Cycling"
        case .dance:                        return "Dance"
        case .danceInspiredTraining:        return "Dance Inspired Training"
        case .elliptical:                   return "Elliptical"
        case .equestrianSports:             return "Equestrian Sports"
        case .fencing:                      return "Fencing"
        case .fishing:                      return "Fishing"
        case .functionalStrengthTraining:   return "Functional Strength Training"
        case .golf:                         return "Golf"
        case .gymnastics:                   return "Gymnastics"
        case .handball:                     return "Handball"
        case .hiking:                       return "Hiking"
        case .hockey:                       return "Hockey"
        case .hunting:                      return "Hunting"
        case .lacrosse:                     return "Lacrosse"
        case .martialArts:                  return "Martial Arts"
        case .mindAndBody:                  return "Mind and Body"
        case .mixedMetabolicCardioTraining: return "Mixed Metabolic Cardio Training"
        case .paddleSports:                 return "Paddle Sports"
        case .play:                         return "Play"
        case .preparationAndRecovery:       return "Preparation and Recovery"
        case .racquetball:                  return "Racquetball"
        case .rowing:                       return "Rowing"
        case .rugby:                        return "Rugby"
        case .running:                      return "Running"
        case .sailing:                      return "Sailing"
        case .skatingSports:                return "Skating Sports"
        case .snowSports:                   return "Snow Sports"
        case .soccer:                       return "Soccer"
        case .softball:                     return "Softball"
        case .squash:                       return "Squash"
        case .stairClimbing:                return "Stair Climbing"
        case .surfingSports:                return "Surfing Sports"
        case .swimming:                     return "Swimming"
        case .tableTennis:                  return "Table Tennis"
        case .tennis:                       return "Tennis"
        case .trackAndField:                return "Track and Field"
        case .traditionalStrengthTraining:  return "Traditional Strength Training"
        case .volleyball:                   return "Volleyball"
        case .walking:                      return "Walking"
        case .waterFitness:                 return "Water Fitness"
        case .waterPolo:                    return "Water Polo"
        case .waterSports:                  return "Water Sports"
        case .wrestling:                    return "Wrestling"
        case .yoga:                         return "Yoga"

        // iOS 10
        case .barre:                        return "Barre"
        case .coreTraining:                 return "Core Training"
        case .crossCountrySkiing:           return "Cross Country Skiing"
        case .downhillSkiing:               return "Downhill Skiing"
        case .flexibility:                  return "Flexibility"
        case .highIntensityIntervalTraining:    return "High Intensity Interval Training"
        case .jumpRope:                     return "Jump Rope"
        case .kickboxing:                   return "Kickboxing"
        case .pilates:                      return "Pilates"
        case .snowboarding:                 return "Snowboarding"
        case .stairs:                       return "Stairs"
        case .stepTraining:                 return "Step Training"
        case .wheelchairWalkPace:           return "Wheelchair Walk Pace"
        case .wheelchairRunPace:            return "Wheelchair Run Pace"

        // iOS 11
        case .taiChi:                       return "Tai Chi"
        case .mixedCardio:                  return "Mixed Cardio"
        case .handCycling:                  return "Hand Cycling"

        // iOS 13
        case .discSports:                   return "Disc Sports"
        case .fitnessGaming:                return "Fitness Gaming"

        // Catch-all
        default:                            return "Other"
        }
    }

    var associatedEmoji: String? {
        switch self {
        case .americanFootball:             return "🏈"
        case .archery:                      return "🏹"
        case .badminton:                    return "🏸"
        case .baseball:                     return "⚾️"
        case .basketball:                   return "🏀"
        case .bowling:                      return "🎳"
        case .boxing:                       return "🥊"
        case .curling:                      return "🥌"
        case .cycling:                      return "🚲"
        case .equestrianSports:             return "🏇"
        case .fencing:                      return "🤺"
        case .fishing:                      return "🎣"
        case .functionalStrengthTraining:   return "💪"
        case .golf:                         return "⛳️"
        case .hiking:                       return "🥾"
        case .hockey:                       return "🏒"
        case .lacrosse:                     return "🥍"
        case .martialArts:                  return "🥋"
        case .mixedMetabolicCardioTraining: return "❤️"
        case .paddleSports:                 return "🛶"
        case .rowing:                       return "🛶"
        case .rugby:                        return "🏉"
        case .sailing:                      return "⛵️"
        case .skatingSports:                return "⛸"
        case .snowSports:                   return "🛷"
        case .soccer:                       return "⚽️"
        case .softball:                     return "🥎"
        case .tableTennis:                  return "🏓"
        case .tennis:                       return "🎾"
        case .traditionalStrengthTraining:  return "🏋️‍♂️"
        case .volleyball:                   return "🏐"
        case .waterFitness, .waterSports:   return "💧"

        // iOS 10
        case .barre:                        return "🥿"
        case .crossCountrySkiing:           return "⛷"
        case .downhillSkiing:               return "⛷"
        case .kickboxing:                   return "🥋"
        case .snowboarding:                 return "🏂"

        // iOS 11
        case .mixedCardio:                  return "❤️"

        // iOS 13
        case .discSports:                   return "🥏"
        case .fitnessGaming:                return "🎮"

        // Catch-all
        default:                            return "🧍"
        }
    }

    enum EmojiGender {
        case male
        case female
    }

    var associatedEmojiFemale: String? {
        switch self {
        case .climbing: return "🧗‍♀️"
        case .dance, .danceInspiredTraining: return "💃"
        case .gymnastics, .highIntensityIntervalTraining: return "🤸‍♀️"
        case .handball: return "🤾‍♀️"
        case .mindAndBody, .yoga, .flexibility: return "🧘‍♀️"
        case .preparationAndRecovery: return "🙆‍♀️"
        case .running: return "🏃‍♀️"
        case .surfingSports: return "🏄‍♀️"
        case .swimming: return "🏊‍♀️"
        case .walking: return "🚶‍♀️"
        case .waterPolo: return "🤽‍♀️"
        case .wrestling: return "🤼‍♀️"

        // Catch-all
        default:                            return associatedEmoji
        }
    }

    var associatedEmojiMale: String? {
        switch self {
        case .climbing: return "🧗🏻‍♂️"
        case .dance, .danceInspiredTraining: return "🕺🏿"
        case .gymnastics, .highIntensityIntervalTraining: return "🤸‍♂️"
        case .handball: return "🤾‍♂️"
        case .mindAndBody, .yoga, .flexibility: return "🧘‍♂️"
        case .preparationAndRecovery: return "🙆‍♂️"
        case .running: return "🏃‍♂️"
        case .surfingSports: return "🏄‍♂️"
        case .swimming: return "🏊‍♂️"
        case .walking: return "🚶‍♂️"
        case .waterPolo: return "🤽‍♂️"
        case .wrestling: return "🤼‍♂️"

        // Catch-all
        default:                            return associatedEmoji
        }
    }

    func associatedEmoji(for gender: EmojiGender) -> String? {
        switch gender {
        case .female: return associatedEmojiFemale
        case .male: return associatedEmojiMale
        }
    }
}
