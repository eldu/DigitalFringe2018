
#define M_PI 3.14159265

uniform sampler2D texture;
uniform int u_useTexture;
uniform vec3 u_albedo;
uniform vec3 u_ambient;
uniform vec3 u_lightPos;
uniform vec3 u_lightCol;
uniform float u_lightIntensity;

uniform vec3 u_camPos;

varying vec3 f_position;
varying vec3 f_normal;
varying vec2 f_uv;

varying vec3 look;

// void main() {
//     vec4 color = vec4(u_albedo, 1.0);
    
//     if (u_useTexture == 1) {
//         color = texture2D(texture, f_uv);
//     }

//     float d = clamp(dot(f_normal, normalize(u_lightPos - f_position)), 0.0, 1.0);

//     vec3 look = -normalize(f_position - u_camPos);

//     if (clamp(dot(f_normal, look), 0.0, 1.0) < 0.4) {
//     	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
//     } else {
// 	    d = floor(d * 4.0) * 0.25; // 10 Bins		
// 	    gl_FragColor = vec4(d * color.rgb * u_lightCol * u_lightIntensity + u_ambient, 1.0);
//     }
// }


// https://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise_gen2(float x, float y, float z) {
    return fract(sin(dot(vec3(x, y, z), vec3(12.9898, 78.233, 43.29179))) * 43758.5453);
}

// Cosine Interpolation
float cerp (float a, float b, float x) {
    float y = x * M_PI;
    y = (1.0 - cos(y)) * 0.5; // y is inbetween[0, 1]
    return a * (1.0 - y) + b * y; // map y between a and b
}

float smoothNoise(float x, float y, float z) {
    float center = noise_gen2(x, y, z) / 8.0;
    float adj = (noise_gen2(x + 1., y, z) + noise_gen2(x - 1., y, z)
               + noise_gen2(x, y + 1., z) + noise_gen2(x, y - 1., z)
               + noise_gen2(x, y, z + 1.) + noise_gen2(z, y, z - 1.)) / 16.0;
    float diag = (noise_gen2(x + 1., y + 1., z)
                + noise_gen2(x + 1., y - 1., z)
                + noise_gen2(x - 1., y + 1., z)
                + noise_gen2(x - 1., y - 1., z)
                + noise_gen2(x + 1., y, z + 1.)
                + noise_gen2(x + 1., y, z - 1.)
                + noise_gen2(x - 1., y, z + 1.)
                + noise_gen2(x - 1., y, z - 1.)
                + noise_gen2(x, y + 1., z + 1.)
                + noise_gen2(x, y + 1., z - 1.)
                + noise_gen2(x, y - 1., z + 1.)
                + noise_gen2(x, y - 1., z - 1.)) / 32.0;
    float corners = (noise_gen2(x + 1., y + 1., z + 1.)
                    + noise_gen2(x + 1., y + 1., z - 1.) 
                    + noise_gen2(x + 1., y - 1., z + 1.) 
                    + noise_gen2(x + 1., y - 1., z - 1.) 
                    + noise_gen2(x - 1., y + 1., z + 1.) 
                    + noise_gen2(x - 1., y + 1., z - 1.) 
                    + noise_gen2(x - 1., y - 1., z + 1.) 
                    + noise_gen2(x - 1., y - 1., z - 1.)) / 64.0;
        
    return center + adj + diag + corners;
}

float interpSmoothNoise3D(float x, float y, float z) {
    // Get integer and fraction portions of x, y, z
    float intX = floor(x);
    float fractX = fract(x);
    float intY = floor(y);
    float fractY = fract(y);
    float intZ = floor(z);
    float fractZ = fract(z);

    //  Point of the cube
    float c000 = noise_gen2(intX,     intY,     intZ     );
    float c001 = noise_gen2(intX,     intY,     intZ + 1. );
    float c010 = noise_gen2(intX,     intY + 1., intZ     );
    float c011 = noise_gen2(intX,     intY + 1., intZ + 1. );
    float c100 = noise_gen2(intX + 1., intY,     intZ     );
    float c101 = noise_gen2(intX + 1., intY,     intZ + 1. );
    float c110 = noise_gen2(intX + 1., intY + 1., intZ     );
    float c111 = noise_gen2(intX + 1., intY + 1., intZ + 1. );

    // //  Point of the cube
    // float c000 = smoothNoise(intX,     intY,     intZ     );
    // float c001 = smoothNoise(intX,     intY,     intZ + 1. );
    // float c010 = smoothNoise(intX,     intY + 1., intZ     );
    // float c011 = smoothNoise(intX,     intY + 1., intZ + 1. );
    // float c100 = smoothNoise(intX + 1., intY,     intZ     );
    // float c101 = smoothNoise(intX + 1., intY,     intZ + 1. );
    // float c110 = smoothNoise(intX + 1., intY + 1., intZ     );
    // float c111 = smoothNoise(intX + 1., intY + 1., intZ + 1. );

    // Interpolate over X
    float c00 = cerp(c000, c100, fractX);
    float c01 = cerp(c001, c101, fractX);
    float c10 = cerp(c010, c110, fractX);
    float c11 = cerp(c011, c111, fractX);

    // Interpolate over Y
    float c0 = cerp(c00, c10, fractY);
    float c1 = cerp(c01, c11, fractY);

    // Interpolate over Z
    return cerp(c0, c1, fractZ);
}

float fbm3D(float x, float y, float z) {
    float total = 0.0;
    float persistance = 0.5;
    // int octaves = 4;


    for (int i = 0; i < 4; i++) {
        float frequency = float(i * i);
        float amplitude = pow(persistance, 1.0); //pow(persistance, i);

        total += interpSmoothNoise3D(x * frequency, y * frequency, z * frequency) * amplitude;
    }

    return total;
}

float map(float value, float start1, float stop1, float start2, float stop2) {
    float decimal = (value - start1)/(stop1 - start1);
    return decimal * (stop2 - start2) + start2;
}

float decimal(float value, float start, float stop) {
    return (value - start)/(stop - start);
}

// Reference 
// https://gist.github.com/gre/1650294
float easeOutQuint (float t) { 
    return 1.0 + (t - 1.0) * t * t * t * t; 
}

float easeInQuint (float t) {
    return t * t * t * t * t;
}

float easeInOutQuint (float t) { 
    return t < 0.5 ? 16.0 * t * t * t * t * t : 1.0 + 16.0 * (t - 1.0) * t * t * t * t; 
}

float easeInOutCubic (float t) { 
    return t < 0.5 ? 4.0 * t * t * t : (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0 ) + 1.0;
}

void main() {
    vec4 color = vec4(u_albedo, 1.0);
    
    if (u_useTexture == 1) {
        color = texture2D(texture, f_uv);
    }

    float d = clamp(dot(f_normal, normalize(u_lightPos - f_position)), 0.0, 1.0);

    vec3 look = -normalize(f_position - u_camPos);

    float ctrl_turb = fbm3D(f_position.x, f_position.y, f_position.z);
    float edge = clamp(dot(f_normal, look), 0.0, 1.0);

    vec3 c = d * color.rgb * u_lightCol * u_lightIntensity + u_ambient;

    if (edge < 0.3) {
        float temp = easeOutQuint(decimal(edge, 0.0, 0.3));
        vec3 c = d * color.rgb * u_lightCol * u_lightIntensity + u_ambient;
        gl_FragColor = vec4(temp * c, 1.0);
    } else {
        float gray = dot(c, vec3(0.299, 0.587, 0.114));

        //d = floor(d * 4.0) * 0.25;  
        d = easeInOutCubic(d);

        vec3 c = d * color.rgb * u_lightCol * u_lightIntensity + u_ambient;

        gl_FragColor = vec4((ctrl_turb * 0.6 * gray) + c, 1.0);
    }
}