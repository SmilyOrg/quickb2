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
	import TopDown.*;
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTorqueCurve
	{
		private var entries:Vector.<tdTorqueEntry> = new Vector.<tdTorqueEntry>();
		
		public function tdTorqueCurve():void
		{
			
		}
		
		public function clone():tdTorqueCurve
		{
			var newCurve:tdTorqueCurve = new tdTorqueCurve();
			for ( var i:uint = 0; i < entries.length; i++ )
				newCurve.addEntry(entries[i].RPM, entries[i].torque);
			return newCurve;
		}
		
		// Adds the entry to a sorted list using a simple binary search insertion.
		public function addEntry(RPM:Number, torque:Number):void
		{
			var min:int = 0, max:int = entries.length;
			var splitIndex:int = (max - min) / 2;
			var found:Boolean = false;
			var newEntry:tdTorqueEntry = new tdTorqueEntry();
			newEntry._torque = torque;
			newEntry._rpm = RPM;
			while ( !found )
			{
				if ( splitIndex == min || splitIndex == max )
				{
					if ( !entries.length )
					{
						entries.push(newEntry);
					}
					else if ( RPM >= entries[splitIndex].RPM )
					{
						if ( splitIndex == entries.length - 1 )
						{
							entries.push(newEntry);
						}
						else
						{
							entries.splice(splitIndex + 1, 0, newEntry);
						}
					}
					
					else
					{
						if ( splitIndex == 0 )
						{
							entries.unshift(newEntry);
						}
						else
						{
							entries.splice(splitIndex, 0, newEntry);
						}
					}
					
					break;
				}
				if ( RPM >= entries[splitIndex].RPM )
				{
					min = splitIndex;
					splitIndex += (max - min) / 2;
				}
				else
				{
					max = splitIndex;
					splitIndex -= (max - min) / 2;
				}
			}
			
			if ( !highestEntry || torque > highestEntry.torque )
			{
				highestEntry = newEntry;
			}
		}
		
		private var highestEntry:tdTorqueEntry = null;
		
		public function get idealRPM():Number
		{
			if ( !highestEntry )  return -1;
			
			return highestEntry.RPM;
		}
		
		public function getTorque(atRPM:Number):Number
		{
			if ( entries.length <= 1 )  return 0;
			
			//--- Do a binary search for the closest rpm value on the curve, then linearly interpolate if needed.
			var min:int = 0, max:int = entries.length;
			var splitIndex:int = (max - min) / 2;
			var found:Boolean = false;
			while ( !found )
			{
				if ( splitIndex == min || splitIndex == max )
				{
					if ( splitIndex == 0 )
					{
						if( atRPM <= entries[splitIndex].RPM )
							return entries[splitIndex].torque;
						else
							return interpolateTorque(atRPM, entries[splitIndex], entries[splitIndex + 1]);
					}
					else if ( splitIndex == entries.length - 1)
					{
						if ( atRPM >= entries[splitIndex].RPM )
						{
							return 0; // effectively we're past the engine's highest RPM rating, meaning in real life the engine would probably explode...so i think zero torque is appropriate
						}
						else
							return interpolateTorque(atRPM, entries[splitIndex-1], entries[splitIndex]);
					}
					else
					{
						if ( atRPM < entries[splitIndex].RPM )
							return interpolateTorque(atRPM, entries[splitIndex-1], entries[splitIndex]);
						else
							return interpolateTorque(atRPM, entries[splitIndex], entries[splitIndex + 1]);
					}
				}
				
				if ( atRPM >= entries[splitIndex].RPM )
				{
					min = splitIndex;
					splitIndex += (max - min) / 2;
				}
				else
				{
					max = splitIndex;
					splitIndex -= (max - min) / 2;
				}
			}
			return 0;
		}
		
		private function interpolateTorque(rpm:Number, entry1:tdTorqueEntry, entry2:tdTorqueEntry):Number
		{
			var ratio:Number = (rpm-entry1.RPM) / (entry2.RPM - entry1.RPM);
			return entry1.torque + (entry2.torque - entry1.torque) * ratio;
		}
		
		public function get numEntries():uint
		{
			return entries.length;
		}
		
		public function getEntryAt(index:uint):tdTorqueEntry
			{  return entries[index];  }
		
		public function get minRPM():Number
		{
			if ( !entries.length )  return -1;
			return entries[0].RPM;
		}
		
		public function get maxRPM():Number
		{
			if ( !entries.length )  return -1;
			return entries[entries.length - 1].RPM;
		}
		
		public function get minRadsPerSec():Number
		{
			if ( !entries.length )  return 0;
			
			return qb2UnitConverter.RPM_to_radsPerSec(entries[0].RPM);
		}
		
		public function get maxRadsPerSec():Number
		{
			if ( !entries.length )  return 0;
			
			return qb2UnitConverter.RPM_to_radsPerSec(entries[entries.length - 1].RPM);
		}
	}
}


