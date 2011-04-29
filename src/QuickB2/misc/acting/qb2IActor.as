/**
 * Copyright (c) 2010 Doug Koellmer
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

package QuickB2.misc.acting 
{
	import As3Math.geo2d.amPoint2d;
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public interface qb2IActor 
	{
		function getX():Number;
		function setX(value:Number):qb2IActor;
		
		function getY():Number;
		function setY(value:Number):qb2IActor;
		
		function getPosition():amPoint2d;
		function setPosition(point:amPoint2d):qb2IActor;
		
		function getRotation():Number;
		function setRotation(value:Number):qb2IActor;
		
		function scaleBy(xValue:Number, yValue:Number):qb2IActor
		
		function getParentActor():qb2IActorContainer;
		
		function clone(deep:Boolean = true):qb2IActor;
	}
}