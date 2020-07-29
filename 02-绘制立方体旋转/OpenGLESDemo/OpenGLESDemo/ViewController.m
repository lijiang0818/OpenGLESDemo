//
//  ViewController.m
//  OpenGLESDemo
//
//  Created by lijiang on 2020/7/27.
//  Copyright © 2020 lijiang. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "ViewController.h"


typedef struct {
    GLKVector3 positionCoord;   //顶点坐标
    GLKVector2 textureCoord;    //纹理坐标
    GLKVector3 normal;          //法线
} CCVertex;

// 顶点数
static NSInteger const kCoordCount = 36;

@interface ViewController () <GLKViewDelegate>

@property (nonatomic, strong) GLKView *glkView;
@property (nonatomic, strong) GLKBaseEffect *baseEffect;
@property (nonatomic, assign) CCVertex *vertices;

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSInteger angle;
@property (nonatomic, assign) GLuint vertexBuffer;

@end

@implementation ViewController

- (void)dealloc {
    
    if ([EAGLContext currentContext] == self.glkView.context) {
        [EAGLContext setCurrentContext:nil];
    }
    if (_vertices) {
        free(_vertices);
        _vertices = nil;
    }
    
    if (_vertexBuffer) {
        glDeleteBuffers(1, &_vertexBuffer);
        _vertexBuffer = 0;
    }
    
    //displayLink 失效
    [self.displayLink invalidate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //1.View背景色
    self.view.backgroundColor = [UIColor blackColor];
    
    //1.OpenGL ES 相关初始化
    [self commonInit];
    
    //2.加载顶点&纹理坐标数据
    [self setupVertex];
    
    //3. 添加CADisplayLink
    [self addCADisplayLink];
    

    
}

-(void) addCADisplayLink{
   
    //CADisplayLink 类似定时器,提供一个周期性调用.属于QuartzCore.framework中.
    //具体可以参考该博客 https://www.cnblogs.com/panyangjun/p/4421904.html
    self.angle = 0;
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

-(void)commonInit
{
    
    //1.创建context
    EAGLContext *context = [[EAGLContext alloc]initWithAPI: kEAGLRenderingAPIOpenGLES2];
    //设置当前context
    [EAGLContext setCurrentContext:context];
    
    //2.创建GLKView并设置代理
    CGRect frame = CGRectMake(0, 100, self.view.frame.size.width, self.view.frame.size.width);
    self.glkView = [[GLKView alloc]initWithFrame:frame context:context];
    self.glkView.backgroundColor = [UIColor clearColor];
    self.glkView.delegate = self;
    
    /*3.配置视图创建的渲染缓存区.
     
     (1). drawableColorFormat: 颜色缓存区格式.
     简介:  OpenGL ES 有一个缓存区，它用以存储将在屏幕中显示的颜色。你可以使用其属性来设置缓冲区中的每个像素的颜色格式。
     
     GLKViewDrawableColorFormatRGBA8888 = 0,
     默认.缓存区的每个像素的最小组成部分（RGBA）使用8个bit，（所以每个像素4个字节，4*8个bit）。
     
     GLKViewDrawableColorFormatRGB565,
     如果你的APP允许更小范围的颜色，即可设置这个。会让你的APP消耗更小的资源（内存和处理时间）
     
     (2). drawableDepthFormat: 深度缓存区格式
     
     GLKViewDrawableDepthFormatNone = 0,意味着完全没有深度缓冲区
     GLKViewDrawableDepthFormat16,
     GLKViewDrawableDepthFormat24,
     如果你要使用这个属性（一般用于3D游戏），你应该选择GLKViewDrawableDepthFormat16
     或GLKViewDrawableDepthFormat24。这里的差别是使用GLKViewDrawableDepthFormat16
     将消耗更少的资源
     
     */
    self.glkView.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    //默认是(0, 1)，这里用于翻转 z 轴，使正方形朝屏幕外
    glDepthRangef(1, 0);
    
    //4.将GLKView 添加self.view 上
    [self.view addSubview:self.glkView];
    
    //5.获取纹理图片
    NSString *imagePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"banner.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
    
    //6.设置纹理参数 纹理坐标原点是左下角,但是图片显示原点应该是左上角.
    NSDictionary *options = @{GLKTextureLoaderOriginBottomLeft : @(YES)};
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:[image CGImage]
                                                               options:options
                                                                 error:NULL];
    
    //7.使用baseEffect
    self.baseEffect = [[GLKBaseEffect alloc]init];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
    //开启光照效果
    self.baseEffect.light0.enabled = YES;
    //漫反射颜色
    self.baseEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    //光源位置
    self.baseEffect.light0.position = GLKVector4Make(-0.5, -0.5, 5, 1);
    
   
}

//加载顶点&纹理坐标数据
- (void)setupVertex{
    
    /*
        解释一下:
        这里我们不复用顶点，使用每 3 个点画一个三角形的方式，需要 12 个三角形，则需要 36 个顶点
        以下的数据用来绘制以（0，0，0）为中心，边长为 1 的立方体
        */
       
       //8. 开辟顶点数据空间(数据结构SenceVertex 大小 * 顶点个数kCoordCount)
       self.vertices = malloc(sizeof(CCVertex) * kCoordCount);
       
       // 前面
       self.vertices[0] = (CCVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 0, 1}};
       self.vertices[1] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
       self.vertices[2] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
       self.vertices[3] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}};
       self.vertices[4] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}};
       self.vertices[5] = (CCVertex){{0.5, -0.5, 0.5}, {1, 0}, {0, 0, 1}};
       
       // 上面
       self.vertices[6] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {0, 1, 0}};
       self.vertices[7] = (CCVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
       self.vertices[8] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
       self.vertices[9] = (CCVertex){{-0.5, 0.5, 0.5}, {0, 1}, {0, 1, 0}};
       self.vertices[10] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {0, 1, 0}};
       self.vertices[11] = (CCVertex){{-0.5, 0.5, -0.5}, {0, 0}, {0, 1, 0}};
       
       // 下面
       self.vertices[12] = (CCVertex){{0.5, -0.5, 0.5}, {1, 1}, {0, -1, 0}};
       self.vertices[13] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
       self.vertices[14] = (CCVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
       self.vertices[15] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}};
       self.vertices[16] = (CCVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}};
       self.vertices[17] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, -1, 0}};
       
       // 左面
       self.vertices[18] = (CCVertex){{-0.5, 0.5, 0.5}, {1, 1}, {-1, 0, 0}};
       self.vertices[19] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
       self.vertices[20] = (CCVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
       self.vertices[21] = (CCVertex){{-0.5, -0.5, 0.5}, {0, 1}, {-1, 0, 0}};
       self.vertices[22] = (CCVertex){{-0.5, 0.5, -0.5}, {1, 0}, {-1, 0, 0}};
       self.vertices[23] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {-1, 0, 0}};
       
       // 右面
       self.vertices[24] = (CCVertex){{0.5, 0.5, 0.5}, {1, 1}, {1, 0, 0}};
       self.vertices[25] = (CCVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
       self.vertices[26] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
       self.vertices[27] = (CCVertex){{0.5, -0.5, 0.5}, {0, 1}, {1, 0, 0}};
       self.vertices[28] = (CCVertex){{0.5, 0.5, -0.5}, {1, 0}, {1, 0, 0}};
       self.vertices[29] = (CCVertex){{0.5, -0.5, -0.5}, {0, 0}, {1, 0, 0}};
       
       // 后面
       self.vertices[30] = (CCVertex){{-0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}};
       self.vertices[31] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
       self.vertices[32] = (CCVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
       self.vertices[33] = (CCVertex){{-0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}};
       self.vertices[34] = (CCVertex){{0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}};
       self.vertices[35] = (CCVertex){{0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}};
       
       //开辟顶点缓存区
        //(1).创建顶点缓存区标识符ID
       glGenBuffers(1, &_vertexBuffer);
          //(2).绑定顶点缓存区.(明确作用)
       glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        //(3).将顶点数组的数据copy到顶点缓存区中(GPU显存中)
       GLsizeiptr bufferSizeBytes = sizeof(CCVertex) * kCoordCount;
       glBufferData(GL_ARRAY_BUFFER, bufferSizeBytes, self.vertices, GL_STATIC_DRAW);
       
       
       /*
         (1)在iOS中, 默认情况下，出于性能考虑，所有顶点着色器的属性（Attribute）变量都是关闭的.
         意味着,顶点数据在着色器端(服务端)是不可用的. 即使你已经使用glBufferData方法,将顶点数据从内存拷贝到顶点缓存区中(GPU显存中).
         所以, 必须由glEnableVertexAttribArray 方法打开通道.指定访问属性.才能让顶点着色器能够访问到从CPU复制到GPU的数据.
         注意: 数据在GPU端是否可见，即，着色器能否读取到数据，由是否启用了对应的属性决定，这就是glEnableVertexAttribArray的功能，允许顶点着色器读取GPU（服务器端）数据。
         
         (2)方法简介
         glVertexAttribPointer (GLuint indx, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid* ptr)
         
         功能: 上传顶点数据到显存的方法（设置合适的方式从buffer里面读取数据）
         参数列表:
         index,指定要修改的顶点属性的索引值,例如
         size, 每次读取数量。（如position是由3个（x,y,z）组成，而颜色是4个（r,g,b,a）,纹理则是2个.）
         type,指定数组中每个组件的数据类型。可用的符号常量有GL_BYTE, GL_UNSIGNED_BYTE, GL_SHORT,GL_UNSIGNED_SHORT, GL_FIXED, 和 GL_FLOAT，初始值为GL_FLOAT。
         normalized,指定当被访问时，固定点数据值是否应该被归一化（GL_TRUE）或者直接转换为固定点值（GL_FALSE）
         stride,指定连续顶点属性之间的偏移量。如果为0，那么顶点属性会被理解为：它们是紧密排列在一起的。初始值为0
         ptr指定一个指针，指向数组中第一个顶点属性的第一个组件。初始值为0
         */
       //顶点数据
       glEnableVertexAttribArray(GLKVertexAttribPosition);
       glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL + offsetof(CCVertex, positionCoord));
       
       //纹理数据
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL + offsetof(CCVertex, textureCoord));
        
        //法线数据
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(CCVertex), NULL + offsetof(CCVertex, normal));
       
    
}


#pragma mark -- GLKViewDelegate
//绘制视图的内容
/*
 GLKView对象使其OpenGL ES上下文成为当前上下文，并将其framebuffer绑定为OpenGL ES呈现命令的目标。然后，委托方法应该绘制视图的内容。
 */
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    //1.开启深度测试
    glEnable(GL_DEPTH_TEST);
    //2.清除颜色缓存区&深度缓存区
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    //3.准备绘制
    [self.baseEffect prepareToDraw];
    //4.绘图
    glDrawArrays(GL_TRIANGLES, 0, kCoordCount);

}

#pragma mark - update
- (void)update {
   
    //1.计算旋转度数
    self.angle = (self.angle + 5) % 360;
    //2.修改baseEffect.transform.modelviewMatrix
    self.baseEffect.transform.modelviewMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle), 0.3, 1, 0.7);
    //3.重新渲染
    [self.glkView display];
}

@end

