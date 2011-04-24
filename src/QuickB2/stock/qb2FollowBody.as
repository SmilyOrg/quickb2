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

package QuickB2.stock
{
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import QuickB2.debugging.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2FollowBody extends qb2Body
	{
		public var targetPoint:amPoint2d = new amPoint2d();
		public var targetRotation:Number = 0;
		
		public var maxLinearVelocity:Number = 100;
		public var maxAngularVelocity:Number = 100;
		public var linearLag:Number = 0;
		public var angularLag:Number = 0;
		
		public var linearSnapTolerance:Number      = .01;
		public var linearDistanceTolerance:Number  = .001;
		public var angularSnapTolerance:Number     = RAD_1;
		public var angularDistanceTolerance:Number = RAD_1/2;
		
		public function qb2FollowBody()
		{
			isKinematic = true;
			
			addEventListener(qb2UpdateEvent.PRE_UPDATE, updateVelocities, null, true);
		}
		
		public function updateVelocities(evt:qb2UpdateEvent):void
		{
			if ( targetPoint )
			{
				var distance:Number = position.distanceTo(targetPoint);
				if ( distance > linearDistanceTolerance )
				{
					if ( distance < linearSnapTolerance )
					{
						position.copy(targetPoint);
						linearVelocity.set(); // zero out the velocity.
					}
					else
					{
						var vec:amVector2d = targetPoint.minus(position);
						var mag:Number = distance / (linearLag+1);						
						var metricMag:Number = qb2UnitConverter.pixelsPerFrame_to_metersPerSecond(mag, worldPixelsPerMeter, world.lastTimeStep);
						if( metricMag > maxLinearVelocity )  vec.setLength(maxLinearVelocity);
						linearVelocity.copy(vec);
					}
				}
				else
				{
					linearVelocity.set(); // just make sure body doesn't continue moving at some really slow speed.
				}
			}
			
			
			var angleDiff:Number = targetRotation - this.rotation;
			if ( Math.abs(angleDiff) > angularDistanceTolerance )
			{
				if ( Math.abs(angleDiff) < angularSnapTolerance )
				{
					rotation = targetRotation;
					angularVelocity = 0;
				}
				else
				{
					var angMag:Number = angleDiff / (angularLag+1);
					angMag = Math.abs(angMag) > maxAngularVelocity ? amUtils.sign(angMag)*maxAngularVelocity : angMag;
					angularVelocity = angMag / world.lastTimeStep;
				}
			}
			else
			{
				angularVelocity = 0;
			}
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2FollowBody = super.clone(deep) as qb2FollowBody;
			
			cloned.targetPoint = this.targetPoint ? this.targetPoint.clone() : null;
			cloned.targetRotation = this.targetRotation;
			
			cloned.maxLinearVelocity = this.maxLinearVelocity;
			cloned.maxAngularVelocity = this.maxAngularVelocity;
			cloned.linearLag = this.linearLag;
			cloned.angularLag = this.angularLag;
			
			cloned.linearSnapTolerance      = this.linearSnapTolerance;
			cloned.linearDistanceTolerance  = this.linearDistanceTolerance;
			cloned.angularSnapTolerance     = this.angularSnapTolerance;
			cloned.angularDistanceTolerance = this.angularDistanceTolerance;
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2FollowBody");  }
	}
}