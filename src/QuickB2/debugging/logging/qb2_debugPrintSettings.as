/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package QuickB2.debugging.logging 
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2_debugPrintSettings 
	{
		/// Default implementation of qb2IConsole for notifications.
		public static var defaultNotificationPrinterClass:Class = qb2FlashPrinter;
		
		/// Default implementation of qb2IConsole for warnings.
		public static var defaultWarningPrinterClass:Class = qb2FlashPrinter;
		
		public static var printerForNotifications:qb2IPrinter = null;
		
		public static var printerForWarnings:qb2IPrinter = null;
		
		public static var printNotifications:Boolean = false;
		
		public static var printWarnings:Boolean = false;
		
		/// The two characters indicating the beginning and end of a class trace.
		public static var classBrackets:String   = "[]";
		
		/// The two characters indicating the beginning and end of the variable list of a class.
		public static var variableBrackets:String     = "()";
		
		/// The character(s) to signify a variable's value.
		public static var equalityCharacter:String = "=";
		
		/// The character(s) delimiting the list of variables for a class.
		public static var variableDelimiter:String      = ", ";
		
		/// Associates a list of class names to the variables that they should spit out for toString() calls.
		public static const classToVariableMap:Object = 
		{
			qb2World:                 ["totalNumPolygons", "totalNumCircles", "totalNumJoints"],
			qb2Body:                  ["mass", "position", "rotation", "linearVelocity", "angularVelocity", "numObjects"],
			qb2Group:                 ["mass", "numObjects"],
			qb2CircleShape:           ["mass", "position", "rotation", "radius"],
			qb2PolygonShape:          ["mass", "position", "rotation", "numVertices"],
			
			qb2Chain:                 ["mass", "numLinks", "length", "linkWidth", "linkThickness", "linkLength"],
			qb2FollowBody:            ["position", "rotation", "targetPosition", "targetRotation"],
			qb2SoftPoly:              ["mass", "numVertices", "subdivision", "isCircle"],
			qb2SoftRod:               ["mass", "numSegments", "length", "width"],
			qb2TripSensor:            ["position", "tripTime", "numVisitors", "numTrippedVisitors"],
			qb2Terrain:      	      ["position", "frictionZMultiplier"],
			qb2SoundField:     	      ["position", "sound"],
			qb2StageWalls:            null,
			
			qb2Joint:                 ["collideConnected", "isActive"],
			qb2DistanceJoint:         ["length", "isRope", "localAnchor1", "localAnchor2", "isActive"],
			qb2MouseJoint:            ["worldTarget", "localAnchor", "isActive"],
			qb2PistonJoint:           ["springK", "hasLimits", "localAnchor1", "localAnchor2", "isActive"],
			qb2RevoluteJoint:         ["springK", "hasLimits", "localAnchor1", "localAnchor2", "isActive"],
			qb2WeldJoint:             ["localAnchor1", "localAnchor2", "isActive"],
			
			qb2GravityField:          ["gravityVector"],
			qb2GravityWellField:      [],
			qb2PlanetaryGravityField: [],
			qb2VibratorField:         ["frequencyHz", "impulseNormal", "minImpulse", "maxImpulse"],
			qb2VortexField:           [],
			qb2WindField:             ["windVector"],
			
			qb2Event:                 ["type"],
			qb2ContainerEvent:        ["type", "parentObject", "childObject"],
			qb2ContactEvent:          ["type", "localObject", "otherObject", "contactPoint", "contactNormal"],
			qb2MassEvent:             ["type", "affectedObject", "massChange", "densityChange", "areaChange"],
			qb2RayCastEvent:          ["type"],
			qb2SubContactEvent:       ["type", "ancestorGroup", "contactPoint", "contactNormal"],
			qb2TripSensorEvent:       ["type", "sensor", "visitingObject"],
			qb2UpdateEvent:           ["type", "object"]
		};
	}
}