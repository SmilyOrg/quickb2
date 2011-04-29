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

package QuickB2.effects 
{
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.utils.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2VibratorField extends qb2EffectField
	{
		public function qb2VibratorField()
		{
			frequencyHz =  1.0 / 60.0;
		}
		
		public function get frequencyHz():Number
			{  return getProperty(qb2_props.FREQUENCY_HZ) as Number;  }
		public function set frequencyHz(value:Number):void
			{  setProperty(qb2_props.FREQUENCY_HZ, value);  }
		
		public var scaleImpulsesByMass:Boolean = true;
		public var minImpulse:Number = 5;
		public var maxImpulse:Number = 5;
		public var vector:amVector2d = new amVector2d(1, 0);
		public var randomizeImpulse:Boolean = false;
		
		private static const impulseVector:amVector2d = new amVector2d();
		
		private var lastVibrationTimes:Dictionary = new Dictionary(true);
		
		public override function applyToRigid(rigid:qb2IRigidObject):void
		{
			var currTime:Number = world ? world.clock : 0;
			
			lastVibrationTimes[rigid] = lastVibrationTimes[rigid] ? lastVibrationTimes[rigid]: 0;
			var sign:Number = lastVibrationTimes[rigid] >= 0 ? 1 : -1;
			var elapsed:Number = currTime - Math.abs(lastVibrationTimes[rigid]);
			
			var modifier:Number = 1;
			if ( elapsed > frequencyHz * 4 || !lastVibrationTimes[rigid] )
			{
				 modifier = .5;
			}
			
			if ( elapsed > frequencyHz )
			{
				impulseVector.copy(vector);
				impulseVector.scaleBy(amUtils.getRandFloat(minImpulse, maxImpulse) * sign * modifier);
				
				if ( randomizeImpulse )
				{
					impulseVector.rotateBy(Math.random() * (AM_PI * 2));
				}
				
				if ( scaleImpulsesByMass )
				{
					impulseVector.scaleBy(rigid.mass);
				}
				
				if ( rigid.ancestorBody )
				{
					rigid.ancestorBody.applyImpulse(rigid.parent.getWorldPoint(rigid.centerOfMass), impulseVector);
				}
				else
				{
					rigid.applyImpulse(rigid.centerOfMass, impulseVector);
				}
				
				lastVibrationTimes[rigid] = currTime * -sign;
			}
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2VibratorField = super.clone(deep) as qb2VibratorField;
			
			cloned.minImpulse = this.minImpulse;
			cloned.maxImpulse = this.maxImpulse;
			cloned.scaleImpulsesByMass = this.scaleImpulsesByMass;
			cloned.vector = this.vector ? this.vector.clone() : null;
			cloned.randomizeImpulse = this.randomizeImpulse;
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2VibratorField");  }
		
	}
}