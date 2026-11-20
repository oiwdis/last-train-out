// Optional pre-device launcher for the stock Godot 4.5.1 runtime.
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include <errno.h>
#include <mach-o/dyld.h>
#include <sys/time.h>
#include <unistd.h>

static NSDictionary *deviceProfile(void) {
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) return nil;
    // The stock 4.5.1 driver recognizes Apple families through Apple9.
    NSInteger family = MTLGPUFamilyApple9;
    while (family >= MTLGPUFamilyApple1 && ![device supportsFamily:(MTLGPUFamily)family]) family--;
    return @{@"family": @(family), @"language": @([MTLCompileOptions new].languageVersion),
             @"argumentBuffers": @(device.argumentBuffersSupport), @"device": device.name};
}

static NSString *userDirectory(NSArray<NSString *> *arguments, NSString *resources) {
    NSFileManager *fs = NSFileManager.defaultManager;
    NSString *support = [fs URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject.path;
    NSUInteger end = [arguments indexOfObject:@"--"];
    NSArray *engineArgs = end == NSNotFound ? arguments : [arguments subarrayWithRange:NSMakeRange(0, end)];
    NSUInteger pos = [engineArgs indexOfObject:@"--main-pack"];
    if (pos == NSNotFound) {
        // External overrides can redirect user://. Leave foreign configurations alone.
        NSString *macos = [[resources stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"MacOS"];
        if ([fs fileExistsAtPath:[macos stringByAppendingPathComponent:@"override.cfg"]]) return nil;
        return [support stringByAppendingPathComponent:@"Godot/app_userdata/Last Train Out"];
    }
    if (pos + 1 >= engineArgs.count) return nil;
    NSString *directory = [engineArgs[pos + 1] stringByDeletingLastPathComponent];
    NSString *override = [NSString stringWithContentsOfFile:[directory stringByAppendingPathComponent:@"override.cfg"]
                                                  encoding:NSUTF8StringEncoding error:NULL];
    // Only recognize the private data override emitted by our packaged fixtures.
    NSString *prefix = @"[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name=\"";
    if (![override hasPrefix:prefix] || ![override hasSuffix:@"\"\n"]) return nil;
    NSString *name = [override substringWithRange:NSMakeRange(prefix.length, override.length - prefix.length - 2)];
    NSCharacterSet *invalid = [[NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"] invertedSet];
    if (![name hasPrefix:@"LTO-"] || [name rangeOfCharacterFromSet:invalid].location != NSNotFound) return nil;
    return [support stringByAppendingPathComponent:name];
}

// Publish complete independent copies exclusively. A game may rewrite its own
// cache; hard-linking a bundle file would let it modify the signed application.
static BOOL installMissing(NSString *from, NSString *to) {
    NSFileManager *fs = NSFileManager.defaultManager;
    if ([fs fileExistsAtPath:to]) return YES;
    NSString *parent = to.stringByDeletingLastPathComponent;
    if (![fs createDirectoryAtPath:parent withIntermediateDirectories:YES attributes:nil error:NULL]) return NO;
    NSString *temp = [parent stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    if (![fs copyItemAtPath:from toPath:temp error:NULL]) return NO;
    BOOL ok = link(temp.fileSystemRepresentation, to.fileSystemRepresentation) == 0 || errno == EEXIST;
    [fs removeItemAtPath:temp error:NULL];
    return ok;
}

static void seedShaders(NSString *resources, NSString *user, NSDictionary *actual) {
    NSString *source = [resources stringByAppendingPathComponent:@"MetalShaders"];
    NSDictionary *profile = [NSDictionary dictionaryWithContentsOfFile:[source stringByAppendingPathComponent:@"Profile.plist"]];
    if (!profile || !user || [NSProcessInfo.processInfo.environment[@"LTO_METAL_SHADER_SEED"] isEqual:@"0"] ||
        NSProcessInfo.processInfo.environment[@"GODOT_MTL_DISABLE_ARGUMENT_BUFFERS"] ||
        [actual[@"family"] integerValue] < [profile[@"family"] integerValue] ||
        [actual[@"language"] integerValue] < [profile[@"language"] integerValue] ||
        [actual[@"argumentBuffers"] integerValue] < [profile[@"argumentBuffers"] integerValue]) {
        puts("[renderer] Metal shader source cache unavailable for this configuration; compiling locally");
        return;
    }
    NSString *dest = [user stringByAppendingPathComponent:@"shader_cache"];
    NSUInteger created = 0, existing = 0, errors = 0;
    for (NSString *key in profile[@"files"]) {
        NSString *target = [dest stringByAppendingPathComponent:key];
        if ([NSFileManager.defaultManager fileExistsAtPath:target]) existing++;
        else if (installMissing([source stringByAppendingPathComponent:key], target)) created++;
        else errors++;
    }
    printf("[renderer] Metal shader source cache: %lu installed, %lu existing, %lu unavailable\n",
           (unsigned long)created, (unsigned long)existing, (unsigned long)errors);
}

static int launch(int argc, const char **argv) {
    struct timeval start;
    gettimeofday(&start, NULL);
    NSArray<NSString *> *args = NSProcessInfo.processInfo.arguments;
    if (argc < 2) {
        fputs("Usage: choose-renderer metal|vulkan [Godot arguments]. Quit the game before choosing a driver.\n", stderr);
        return 2;
    }
    NSString *driver = args[1];
    if ([driver isEqual:@"--device-profile"]) {
        NSDictionary *profile = deviceProfile();
        if (!profile) return 2;
        NSData *data = [NSJSONSerialization dataWithJSONObject:profile options:0 error:NULL];
        fwrite(data.bytes, 1, data.length, stdout);
        return 0;
    }
    if (![driver isEqual:@"metal"] && ![driver isEqual:@"vulkan"]) return 2;
    NSArray *rest = [args subarrayWithRange:NSMakeRange(2, argc - 2)];
    for (NSString *arg in rest) {
        if ([arg isEqual:@"--"] || [arg isEqual:@"++"]) break;
        if ([arg hasPrefix:@"--rendering-"] || [arg isEqual:@"--headless"] || [arg isEqual:@"--display-driver"]) {
            fputs("Choose one windowed renderer with the first argument. Use the bundle executable for headless tests.\n", stderr);
            return 2;
        }
    }
    uint32_t size = 0;
    _NSGetExecutablePath(NULL, &size);
    NSMutableData *buffer = [NSMutableData dataWithLength:size];
    if (_NSGetExecutablePath(buffer.mutableBytes, &size)) return 2;
    NSString *path = [[NSFileManager.defaultManager stringWithFileSystemRepresentation:buffer.bytes
        length:strlen(buffer.bytes)] stringByResolvingSymlinksInPath];
    NSString *binDir = path.stringByDeletingLastPathComponent;
    NSString *contents = binDir.stringByDeletingLastPathComponent;
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:[contents stringByAppendingPathComponent:@"Info.plist"]];
    NSString *exe = info[@"CFBundleExecutable"];
    if (!exe.length) return 2;
    NSString *resources = [contents stringByAppendingPathComponent:@"Resources"];
    if ([driver isEqual:@"metal"]) {
#if defined(__arm64__)
        NSDictionary *profile = deviceProfile();
        if ([profile[@"family"] integerValue] < MTLGPUFamilyApple4) {
            fputs("Native Metal requires a supported Apple Silicon GPU. The game was not started.\n", stderr);
            return 2;
        }
        // 4.5.1 supports first-use Metal libraries. The game draws every
        // preparation view before play; retain an explicit immediate control.
        setenv("GODOT_MTL_SHADER_LOAD_STRATEGY", "lazy", 0);
        printf("[renderer] Metal library policy: %s\n", getenv("GODOT_MTL_SHADER_LOAD_STRATEGY"));
        seedShaders(resources, userDirectory(rest, resources), profile);
        exe = @"LastTrainOutMetal";
#else
        fputs("Godot 4.5.1 native Metal requires the arm64 slice. On an Intel Mac use Vulkan.\n", stderr);
        return 2;
#endif
    }
    setenv("LTO_REQUESTED_RENDERER", driver.UTF8String, 1);
    NSString *epoch = [NSString stringWithFormat:@"%lld", (long long)start.tv_sec * 1000000 + start.tv_usec];
    setenv("LTO_LAUNCH_EPOCH_USEC", epoch.UTF8String, 1);
    printf("[renderer] requested Forward+/%s before Godot initialization\n", driver.UTF8String);
    fflush(stdout);
    NSMutableArray *command = [NSMutableArray arrayWithArray:@[[binDir stringByAppendingPathComponent:exe],
        @"--rendering-method", @"forward_plus", @"--rendering-driver", driver]];
    BOOL hasMainPack = NO;
    for (NSString *arg in rest) {
        if ([arg isEqual:@"--"] || [arg isEqual:@"++"]) break;
        if ([arg isEqual:@"--main-pack"]) hasMainPack = YES;
    }
    if ([driver isEqual:@"metal"] && !hasMainPack) {
        NSString *pack = [info[@"CFBundleExecutable"] stringByAppendingPathExtension:@"pck"];
        [command addObjectsFromArray:@[@"--main-pack", [resources stringByAppendingPathComponent:pack]]];
    }
    BOOL normalLaunch = !hasMainPack;
    for (NSString *arg in rest) {
        if ([arg isEqual:@"--"] || [arg isEqual:@"++"]) break;
        if ([arg isEqual:@"--script"] || [arg isEqual:@"-s"] || [arg isEqual:@"--path"] ||
            [arg hasSuffix:@".tscn"] || [arg hasSuffix:@".scn"]) normalLaunch = NO;
    }
    if (normalLaunch) [command addObject:@"res://scenes/main/journey_loading.tscn"];
    [command addObjectsFromArray:rest];
    char **child = calloc(command.count + 1, sizeof(*child));
    if (!child) return 1;
    for (NSUInteger i = 0; i < command.count; i++) child[i] = (char *)[command[i] UTF8String];
    execv(child[0], child);
    perror("Starting Last Train Out");
    free(child);
    return 1;
}

int main(int argc, const char **argv) {
    @autoreleasepool { return launch(argc, argv); }
}
