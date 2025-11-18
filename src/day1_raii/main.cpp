#include <cassert>
#include <iostream>
#include <stdexcept>
#include <string>

struct FileGuard {
  FILE *fp = nullptr;

  explicit FileGuard(const std::string &path, const std::string &mode)
      : fp(std::fopen(path.c_str(), mode.c_str())) {
    if (!fp)
      throw std::runtime_error("fopen failed: " + path);
  }

  ~FileGuard() {
    if (fp)
      std::fclose(fp);
  }

  FileGuard(const FileGuard &) = delete;
  FileGuard &operator=(const FileGuard &) = delete;

  FileGuard(FileGuard &&other) noexcept : fp(other.fp) { other.fp = nullptr; }
  FileGuard &operator=(FileGuard &&other) noexcept {
    if (this != &other) {
      if (fp) {
        std::fclose(fp);
      }

      fp = other.fp;
      other.fp = nullptr;
    }

    return *this;
  }

  [[nodiscard]] FILE *get() const { return fp; }

  explicit operator bool() const { return (fp != nullptr); }
};

template <typename T> class UniquePtr {
  T *ptr_ = nullptr;

public:
  explicit UniquePtr(T *p = nullptr) noexcept : ptr_(p) {}
  ~UniquePtr() { delete ptr_; }

  UniquePtr(const UniquePtr &) = delete;
  UniquePtr &operator=(const UniquePtr &) = delete;

  UniquePtr(UniquePtr &&other) noexcept : ptr_(other.ptr_) {
    other.ptr_ = nullptr;
  }
  UniquePtr &operator=(UniquePtr &&other) noexcept {
    if (this != &other) {
      delete ptr_;
      ptr_ = other.ptr_;
      other.ptr_ = nullptr;
    }

    return *this;
  }

  [[nodiscard]] T *get() const noexcept { return ptr_; }

  T &operator*() const noexcept {
    assert(ptr_ && "dereferencing null UniquePtr");
    return *ptr_;
  }
  T *operator->() const noexcept {
    assert(ptr_ && "arrow on null UniquePtr");
    return ptr_;
  }

  explicit operator bool() const noexcept { return ptr_ != nullptr; }

  T *release() noexcept {
    T *p = ptr_;
    ptr_ = nullptr;
    return p;
  }

  void reset(T *p = nullptr) noexcept {
    if (ptr_ != p) {
      delete ptr_;
      ptr_ = p;
    }
  }
};

void test_fileguard() {
  const char *fname = "test_day1.txt";
  {
    const FileGuard f(fname, "w");
    std::fprintf(f.get(), "RAII on Apple Silicon!\n");
    std::fflush(f.get());
  }
  {
    FILE *check = std::fopen(fname, "r");
    if (!check)
      throw std::runtime_error("File not written");
    char buf[100] = {};
    std::fread(buf, 1, sizeof(buf) - 1, check);
    std::fclose(check);
    if (!std::strstr(buf, "Apple Silicon"))
      throw std::runtime_error("Bad content");
  }
  std::remove(fname);
  std::cout << "[✓] FileGuard OK\n";
}

void test_uniqueptr() {
  UniquePtr<int> p(new int(42));
  UniquePtr<int> q = std::move(p);
  if (p || *q != 42)
    throw std::logic_error("move failed");
  q.reset(new int(100));
  if (*q != 100)
    throw std::logic_error("reset failed");
  std::cout << "[✓] UniquePtr OK\n";
}

int main() {
  std::cout << "=== Day 1: RAII & Move ===\n";
  test_fileguard();
  test_uniqueptr();
  std::cout << "[🎉] Success!\n";
  return 0;
}
