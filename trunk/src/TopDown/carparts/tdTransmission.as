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
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import TopDown.*;
	import TopDown.objects.*;
	
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTransmission extends qb2Object
	{
		// 3.5, 3.5, 3, 2.5, 2, 1.5, 1
		
		public static const TRANNY_AUTOMATIC:uint = 1;
		public static const TRANNY_MANUAL:uint    = 2;
		
		public var torqueConversion:Number = .8;
		public var differential:Number = 3.5;
		public var shiftTime:Number = .25;
		private var shiftStartTime:Number = 0;
		public var gearRatios:Vector.<Number> = new Vector.<Number>();
		public var efficiency:Number = .7;
		public var transmissionType:uint = TRANNY_AUTOMATIC;
		
		public var shiftingInterruptible:Boolean = false;
		
		public function get clutchEngaged():Boolean
			{  return _clutchEngaged;  };
		protected var _clutchEngaged:Boolean = true;
		
		public function tdTransmission()
		{
		}
		
		td_friend var _carBody:tdCarBody;
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var tranny:tdTransmission = super.clone(deep) as tdTransmission;
			
			tranny.torqueConversion = torqueConversion;
			tranny.differential = differential;
			tranny.gearRatios = gearRatios.slice(0, gearRatios.length);
			tranny.efficiency = efficiency;
			tranny.transmissionType = transmissionType;
			tranny.shiftTime = shiftTime;
			tranny.shiftingInterruptible = shiftingInterruptible;
			
			return tranny;
		}
		
		private var _lastForwardBack:Number = 0;
		
		protected override function update():void
		{
			var forwardBack:Number = _carBody.brainPort.NUMBER_PORT_1;
			var shiftAccumulator:int = _carBody.brainPort.INTEGER_PORT_1;
			
			if ( _lastForwardBack >= 0 && forwardBack < 0 )
			{
				shift(0);  // shift to reverse if brain switched from froward to back.
			}
			else if ( _lastForwardBack <= 0 && forwardBack > 0 )
			{
				if ( currGear == 0 )
				{
					shiftToOptimalGear(true, true);  // shift to forward if player switched from down arrow to up arrow.
				}
			}
			else if ( _targetGear != _currGear )
			{
				if ( _carBody.world.clock - shiftStartTime >= shiftTime )
				{
					_currGear = _targetGear;
					
					_clutchEngaged = true;
				}
			}
			else
			{
				if ( _targetGear != 0 )
				{
					if ( transmissionType == TRANNY_MANUAL )
					{
						var gear:int = targetGear + shiftAccumulator;
						if ( gear < 1 ) gear = 1;
						else if ( gear > numGears - 1 )  gear = numGears - 1;
						
						if ( gear != targetGear )  shift(gear);
						
						_carBody.brainPort.INTEGER_PORT_1 = 0; // zero out the shift accumulator.
					}
					else if ( transmissionType == TRANNY_AUTOMATIC )
					{
						shiftToOptimalGear();
					}
				}
			}
			
			_lastForwardBack = forwardBack;
		}
		
		public function get inReverse():Boolean
			{  return _currGear == 0;  }
		
		public function get targetGear():uint
			{  return _targetGear;  }
		protected var _targetGear:uint = 1;
		
		public function get currGear():uint
			{  return _currGear;  }
		protected var _currGear:uint = 1;
		
		public function get numGears():uint
			{  return gearRatios ? gearRatios.length : 0;  }
		
		public function shift(toGear:uint):void
		{
			//if ( !shiftingInterruptible && _currGear != _targetGear )  return;
	
			if ( shiftTime == 0 || _currGear == toGear )
			{
				_currGear = _targetGear = toGear;
				_clutchEngaged = true;
			}
			else
			{
				if ( toGear == _targetGear )  return;
				
				shiftStartTime = _carBody.world.clock;
				_targetGear = toGear;
				_clutchEngaged = false;
			}
		}
		
		public function shiftToOptimalGear(forwardOnly:Boolean = true, overrideIfInReverse:Boolean = false ):void
		{
			if ( !overrideIfInReverse && inReverse )  return;
		
			var bestGear:uint = 1;
			var longSpeed:Number = _carBody._kinematics._longSpeed;
			if ( longSpeed < 0 )
			{
				if ( !forwardOnly )
					bestGear = 0;
			}
			else
			{
				var linearSpeed:Number = longSpeed;
				var estimatedTireRotSpeed:Number = linearSpeed / _carBody.tires[0].metricRadius
				var idealRPM:Number = _carBody.engine.torqueCurve.idealRPM;
				var lowestRPMDiff:Number = -1;
				var bestIndex:int = -1;
				var numGears:int = gearRatios.length;
				for ( var i:uint = 1; i < numGears; i++ )
				{
					var engineRPM:Number = qb2UnitConverter.radsPerSec_to_RPM(estimatedTireRotSpeed * gearRatios[i] * differential);
					var diff:Number = Math.abs(engineRPM - idealRPM);
					if ( lowestRPMDiff < 0 || diff < lowestRPMDiff )
					{
						lowestRPMDiff = diff;
						bestIndex = i;
					}
				}
				if ( bestIndex > 0 )  bestGear = bestIndex;
			}
			
			shift(bestGear)
		}
	
		public function shiftUp():void
		{
			if ( _currGear == 0 )  return;
		
			if ( _currGear < gearRatios.length - 1 )
				shift(_currGear + 1);
		}
			
		public function shiftDown():void
		{
			if ( _currGear == 0 )  return;
		
			if( _currGear > 1 )
				shift(_currGear-1);
		}
			
		public function get currGearRatio():Number
			{  return gearRatios.length ? gearRatios[_currGear] : 0;  }
		
		public function calcTireTorque(engineTorque:Number):Number
		{
			return ((engineTorque * currGearRatio) * differential) * efficiency;
		}
		
		/// Does the conversion from engine radians per second to tire radians per second.
		public function calcRadsPerSec(input:Number):Number
		{
			return (input / currGearRatio) / differential;
		}
		
		/// Does the conversion from tire radians per second to engine radians per second.
		public function calcRadsPerSecInv(input:Number):Number
		{
			return (input * currGearRatio) * differential;
		}
	}
}