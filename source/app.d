import std.stdio;
import std.string;
import std.conv;
import std.file;

import derelict.opengl3.gl3;
import derelict.glfw3.glfw3;

GLuint gVAO = 0;
const int CX = 16;
const int CY = 16;
const int CZ = 16;

extern(C) nothrow void errorPrinter(int error, const(char)*description)
{
    try
    {
        writefln("error %d: %s", error, to!string(description));
    }
    catch (Throwable t)
    {
    }
}

GLFWwindow* createWindow()
{
    DerelictGL3.load();
    DerelictGLFW3.load();
    
    glfwSetErrorCallback(&errorPrinter);
  
    if (!glfwInit())
        throw new Exception("Failed to initialize GLFW");

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 2);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);
    
    GLFWwindow* window = glfwCreateWindow(640, 480,
                                          "simstim", null, null);
    if (!window)
        throw new Exception("Window failed to create");

    glfwMakeContextCurrent(window);
    DerelictGL3.reload();
    
    return window;
}

void printGLInfo()
{
    writefln("OpenGL version string: %s", to!string(glGetString(GL_VERSION))); 
    writefln("OpenGL renderer string: %s", to!string(glGetString(GL_RENDERER)));
    writefln("OpenGL vendor string: %s", to!string(glGetString(GL_VENDOR)));
}

GLuint create_shader(string file, GLenum shaderType)
{
    GLint status;
    string bytes = cast(string)read(file);
    const char *bptr = toStringz(bytes);

    GLuint shader = glCreateShader(shaderType);
    glShaderSource(shader, 1, &bptr, null);
    glCompileShader(shader);
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == 0)
    {
        writeln("Error creating shader:\n");
        char foo[500];
        glGetShaderInfoLog(shader, foo.length, null, foo.ptr);
        writeln(foo);
        throw new Exception("");
    }
    return shader;
}

GLuint create_program(GLuint[] shaders)
{
    GLint status;
    GLuint program = glCreateProgram();
    foreach (GLuint shader; shaders)
    {
        glAttachShader(program, shader);
    }
    glLinkProgram(program);
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == 0)
    {
        writeln("glLinkProgram:");
        throw new Exception("");
    }
    return program;
}

void setupTriangle(GLuint program)
{
    GLuint gVBO = 0;
    
    glGenVertexArrays(1, &gVAO);
    glBindVertexArray(gVAO);
    
    // make and bind the VBO
    glGenBuffers(1, &gVBO);
    glBindBuffer(GL_ARRAY_BUFFER, gVBO);
    
    // Put the three triangle verticies into the VBO
    GLfloat vertexData[] = [//  X     Y     Z
                            0.0f, 0.8f, 0.0f,
                            -0.8f,-0.8f, 0.0f,
                            0.8f,-0.8f, 0.0f,
                            ];
    glBufferData(GL_ARRAY_BUFFER, vertexData.length * GLfloat.sizeof,
                 vertexData.ptr, GL_STATIC_DRAW);
    
    // connect the xyz to the "vert" attribute of the vertex shader
    GLint attrib = glGetAttribLocation(program, "vert");

    glEnableVertexAttribArray(attrib);
    glVertexAttribPointer(attrib, 3, GL_FLOAT, GL_FALSE, 0, null);
    
    // unbind the VBO and VAO
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindVertexArray(0);
}

void render(GLFWwindow *window, GLuint program)
{
    glClearColor(0, 0, 0, 1); // black
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // bind the program (the shaders)
    glUseProgram(program);
        
    // bind the VAO (the triangle)
    glBindVertexArray(gVAO);
    
    // draw the VAO
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    // unbind the VAO
    glBindVertexArray(0);
    
    // unbind the program
    glUseProgram(0);
    
    // swap the display buffers (displays what was just drawn)
    glfwSwapBuffers(window);
}

void main(string[] args)
{
    GLFWwindow *window = createWindow();
    printGLInfo();
    
    GLint compile_ok = GL_FALSE, link_ok = GL_FALSE;

    GLuint[] shaders = [create_shader("shaders/simstim.v.glsl", GL_VERTEX_SHADER),
                        create_shader("shaders/simstim.f.glsl", GL_FRAGMENT_SHADER)];
    GLuint program = create_program(shaders);
    setupTriangle(program);
    
    while (!glfwWindowShouldClose(window))
    {
        render(window, program);
        
        glfwPollEvents();
        if (glfwGetKey(window , GLFW_KEY_ESCAPE ) == GLFW_PRESS)
            break;
        
    }
 
    glfwTerminate();
}
