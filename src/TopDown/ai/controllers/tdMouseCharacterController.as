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

package TopDown.ai.controllers 
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import TopDown.ai.controllers.*;
	import TopDown.objects.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdMouseCharacterController extends tdMouseController
	{
		public var distanceDivisor:Number = 10;
		public var maximumSpeed:Number = 8;
		
		public function tdMouseCharacterController(mouseSource:Stage) 
		{
			super(mouseSource);
		}
		
		protected override function activated():void
		{
			if ( host is tdCharacterBody )
			{
				brainPort.open = true;
				super.activated();
			}
			else
			{
				brainPort.open = false;
			}
		}
		
		protected override function update():void
		{
			super.update();
			
			brainPort.clear();
			
			var mousePos:amPoint2d = mousePosition;
			var direction:amVector2d = mousePos.minus(host.position);
			lastDirection.copy(direction);
			direction.scaleBy(1 / distanceDivisor);
			
			if ( direction.length > maximumSpeed )
			{
				direction.length = maximumSpeed;
			}
		
			if( mouseIsDown )
			{
				brainPort.NUMBER_PORT_1 = direction.y;
				brainPort.NUMBER_PORT_2 = direction.x;
			}
			
			if ( mouseIsDown && direction.lengthSquared )
			{
				if ( Math.abs(direction.y) >= Math.abs(direction.x) )
				{
					brainPort.INTEGER_PORT_3 = direction.y < 0 ? tdCharacterBody.FACING_UP : tdCharacterBody.FACING_DOWN;
				}
				else
				{
					brainPort.INTEGER_PORT_3 = direction.x < 0 ? tdCharacterBody.FACING_LEFT : tdCharacterBody.FACING_RIGHT;
				}
			}
		}
	}
}