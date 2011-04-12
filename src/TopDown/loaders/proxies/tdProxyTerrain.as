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

package TopDown.loaders.proxies 
{
	import QuickB2.loaders.proxies.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdProxyTerrain extends qb2ProxyTerrain
	{
		public function tdProxyTerrain():void
		{
			defaultClassName = "TopDown.objects.tdTerrain";
		}

		[Inspectable(defaultValue=1.0)]
		public var rollingFrictionZMultiplier:Number = 1.0;
		
		[Inspectable(defaultValue="0x000000", type=Color)]
		public var slidingSkidColor:uint = 0;
		
		[Inspectable(defaultValue="0x000000", type=Color)]
		public var rollingSkidColor:uint = 0;
		
		[Inspectable(defaultValue=.6)]
		public var slidingSkidAlpha:Number = .6;
		
		[Inspectable(defaultValue=.6)]
		public var rollingSkidAlpha:Number = .6;
		
		[Inspectable(defaultValue=2.0, name='skidDuration (in seconds)')]
		public var skidDuration:Number = 2.0;
		
		[Inspectable(defaultValue=true, type=Boolean)]
		public var drawSlidingSkids:Boolean = true;
		
		[Inspectable(defaultValue=false, type=Boolean)]
		public var drawRollingSkids:Boolean = false;
	}

}