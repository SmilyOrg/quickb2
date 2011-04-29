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
	import As3Math.geo2d.*;
	import QuickB2.debugging.*;
	import QuickB2.debugging.logging.qb2_toString;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2GravityField extends qb2EffectField
	{
		public var vector:amVector2d = new amVector2d();
		
		public override function applyToRigid(rigid:qb2IRigidObject):void
		{
			if ( rigid.ancestorBody )
			{
				rigid.ancestorBody.applyForce(rigid.parent.getWorldPoint(rigid.centerOfMass), vector.scaledBy(rigid.mass));
			}
			else
			{
				rigid.applyForce(rigid.centerOfMass, vector.scaledBy(rigid.mass));
			}
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2GravityField = super.clone(deep) as qb2GravityField;
			
			cloned.vector.copy(this.vector);
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2GravityField");  }
	}
}