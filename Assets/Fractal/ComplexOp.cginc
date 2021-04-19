#ifndef ComplexOp
#define ComplexOp

//========================= Defines
#define PI 3.14159265358979323846

//========================= Complex Numbers Operations
//from https://gist.github.com/NiklasRosenstein/ee1f1b5786f94e17995361c63dafeb3f
float2 c_cjg(in float2 c) 
{
	return float2(c.x, -c.y);
}

float2 c_mul(in float2 a, in float2 b) 
{
	return float2(a.x * b.x - a.y * b.y, a.y * b.x + a.x * b.y);
}

float2 c_pow(in float2 c, int p) 
{
    float2 tmp = float2(1.0,0.0) ;
    for (int i = 0; i < p; ++i) 
    {
        c = c_mul(tmp, c);
    }
    return c;
}

float2 c_div(in float2 a, in float2 b) 
{
    return c_mul(a, c_cjg(b));
}

float c_mag(in float2 c) 
{
    return sqrt(dot(c,c));
}



#endif // ComplexOp