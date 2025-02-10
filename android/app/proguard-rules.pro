# Keep all annotations
-keepattributes *Annotation*

# Keep classes that implement Parcelable
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep all Gson model classes
-keep class com.google.gson.** { *; }

# Retrofit specific rules
-keep class com.yourapp.models.** { *; }
-keep class retrofit2.** { *; }
-keep class okhttp3.** { *; }

# Keep your application classes
-keep class com.yourpackage.** { *; }

# Keep Google Error Prone annotations
-keep class com.google.errorprone.annotations.** { *; }

# Keep javax.annotation package annotations
-keep class javax.annotation.** { *; }

-keepattributes LineNumberTable,SourceFile
-renamesourcefileattribute SourceFile

-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy