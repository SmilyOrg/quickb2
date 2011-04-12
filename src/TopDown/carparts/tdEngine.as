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

package TopDown.carparts
{
	import As3Math.general.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import TopDown.*;
	import TopDown.objects.*;
	
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdEngine extends qb2Object
	{
		public var torqueCurve:tdTorqueCurve = new tdTorqueCurve();

		td_friend var _radsPerSec:Number = 0;
		protected var _torque:Number = 0;
		
		public var constrainRPMs:Boolean = true;
		
		public var cancelThrottleWhenShifting:Boolean = true;
		
		public function tdEngine():void
		{
		}
		
		td_friend var _carBody:tdCarBody;
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var engine:tdEngine = super.clone(deep) as tdEngine;
			engine.cancelThrottleWhenShifting = this.cancelThrottleWhenShifting;
			engine.torqueCurve = this.torqueCurve;
			engine.constrainRPMs = this.constrainRPMs;
			return engine;
		}
		
		public function get rpm():Number
		{
			return qb2UnitConverter.radsPerSec_to_RPM(_radsPerSec);
		}
		
		public function get radsPerSec():Number
		{
			return _radsPerSec;
		}
		td_friend function setRadsPerSec(value:Number):void
		{
			_radsPerSec = constrainRPMs ? amUtils.constrain(value, torqueCurve.minRadsPerSec, torqueCurve.maxRadsPerSec) : value;
		}
		
		public function  get torque():Number
			{  return _torque;  }
		
		public function throttle(quotient:Number):void
		{
			if ( !_carBody.tranny.clutchEngaged && cancelThrottleWhenShifting )
			{
				_torque = 0;
				return;
			}
			
			var rpm:Number = qb2UnitConverter.radsPerSec_to_RPM(_radsPerSec);
			if ( rpm >= torqueCurve.maxRPM )
			{
				if ( _carBody.kinematics.longSpeed < 0 && _carBody.brainPort.NUMBER_PORT_1 > 0 || _carBody.kinematics.longSpeed > 0 && _carBody.brainPort.NUMBER_PORT_1 < 0 )
					rpm -= 1;  // when rpm's max out, no more torque is provided...this is a problem if you're reversing at max rpms and want to change directions...so here's a little hack that drops rpms a hair to provide torque on these directions changes.
			}
			var maxTorque:Number = torqueCurve.getTorque(rpm);
			
			_torque = maxTorque * quotient;
		}
	}
}