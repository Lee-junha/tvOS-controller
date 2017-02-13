//
//  PhysicsComponent.swift
//  tvOS-controller
//
//  Created by Lauren Brown on 12/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import Foundation
import SceneKit

struct GameObject {
    //data attached to each game object in the world
    init() {
        
    }
    
    var sceneNode = SCNNode()
    var physicsVehicle = SCNPhysicsVehicle()
    var colourID : Int = 0
    var points : Int = 0
    var kills : Int = 0
    var playerLastKilledBy : String? = nil
    //AI component?
    //any game logic
    var ID : Int = 0
    //device ID to be used for multiplayer
    var playerID : String? = nil
    
    func GetColour(_ i : Int) -> UIColor {
        
        switch i {
        case 0:
            return UIColor.black
        case 1:
            return UIColor.lightGray
        case 2:
            return UIColor.red
        case 3:
            return UIColor.green
        case 4:
            return UIColor.blue
        case 5:
            return UIColor.yellow
        case 6:
            return UIColor.magenta
        case 7:
            return UIColor.orange
        case 8:
            return UIColor.purple
        default:
            return UIColor.white
        }
    }
}
