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
	public class qb2WindField extends qb2EffectField
	{
		/** 
		 * The wind direction and speed.
		 * @default zero-length vector.
		 */
		public var vector:amVector2d = new amVector2d();
		
		/**
		 * If true, even a zero-length wind vector will make this field apply forces if an object is moving relative to the "air" and airDensity is > 0.
		 * This is the most realistic way to simulate things, but for a game it can make your object look "floaty".  Keeping this false will only apply
		 * forces in the direction of the wind vector.  
		 */
		public var simulateDrag:Boolean = false;
		
		/**
		 * Basically affects how strong the wind is.
		 */
		public var airDensity:Number = 1;
		
		private var utilVec:amVector2d = new amVector2d();
		
		public override function applyToRigid(rigid:qb2IRigidObject):void
		{
			var rigidWorldVel:amVector2d = rigid.getLinearVelocityAtPoint(rigid.centerOfMass);
			
			if ( simulateDrag )
			{
				utilVec.copy(vector);
				
				var relToAir:amVector2d = utilVec.subtract(rigidWorldVel);
				
				utilVec.copy(relToAir.square().scaleBy(.5 * airDensity));
			}
			else
			{
				if ( !rigidWorldVel.lengthSquared )
				{
					utilVec.copy(vector).scaleBy(airDensity);
				}
				else
				{
					utilVec.copy(vector).normalize();
					var dot:Number = rigidWorldVel.dotProduct(utilVec);
					var worldVelProjection:amVector2d = utilVec.scaledBy(dot);
					utilVec.copy(vector);
					utilVec.subtract(worldVelProjection);
					utilVec.scaleBy(airDensity);
				}
			}
			
			if ( rigid.ancestorBody )
			{
				rigid.ancestorBody.applyForce(rigid.parent.getWorldPoint(rigid.centerOfMass), utilVec);
			}
			else
			{
				rigid.applyForce(rigid.centerOfMass, utilVec);
			}
		}
		
		public override function clone(deep:Boolean = true):qb2Object
		{
			var cloned:qb2WindField = super.clone(deep) as qb2WindField;
			
			cloned.vector.copy(this.vector);
			cloned.airDensity = this.airDensity;
			cloned.simulateDrag = this.simulateDrag;
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2_toString(this, "qb2WindField");  }
		
	}
}