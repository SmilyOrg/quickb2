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
	import As3Math.geo2d.amVector2d;
	import demos.RigidCar;
	import QuickB2.debugging.qb2DebugTraceUtils;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2Group;
	import QuickB2.objects.tangibles.qb2IRigidObject;
	import QuickB2.objects.tangibles.qb2Tangible;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2GravityField extends qb2EffectField
	{
		public var gravityVector:amVector2d = new amVector2d();
		
		public override function applyToRigid(rigid:qb2IRigidObject):void
		{
			if ( rigid.ancestorBody )
			{
				rigid.ancestorBody.applyForce(rigid.parent.getWorldPoint(rigid.centerOfMass), gravityVector.scaledBy(rigid.mass));
			}
			else
			{
				rigid.applyForce(rigid.centerOfMass, gravityVector.scaledBy(rigid.mass));
			}
		}
		
		public override function clone():qb2Object
		{
			var cloned:qb2GravityField = super.clone() as qb2GravityField;
			
			cloned.gravityVector.copy(this.gravityVector);
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2GravityField");  }
	}
}