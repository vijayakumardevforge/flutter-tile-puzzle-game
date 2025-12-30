class PuzzleAssets {
  static final List<String> easyImages = [
    'assets/images/baby_panda.png',
    'assets/images/baby_tiger.png',
    'assets/images/baby_elephant.png',
    'assets/images/ai_bunny.png',
    'assets/images/ai_fish.png',
    'assets/images/ai_bird.png',
    'assets/images/ai_flower.png',
    'assets/images/ai_baby_robot.png',
    'assets/images/ai_pet.png',
    'assets/images/bears.png',
  ];

  static final List<String> mediumImages = [
    'assets/images/ai_butterfly.png',
    'assets/images/ai_tree.png',
    'assets/images/ai_fox.png',
    'assets/images/ai_robot.png',
    'assets/images/ai_city.png',
    'assets/images/ai_drone.png',
    'assets/images/ai_cat.png',
    'assets/images/ai_space.png',
    'assets/images/ai_plant.png',
    'assets/images/ai_chip.png',
  ];

  static final List<String> hardImages = [
    'assets/images/ai_cloud.png',
    'assets/images/ai_rocket.png',
    'assets/images/dolls.jpg',
    'assets/images/pattern.jpg',
    'assets/images/pink_face.png',
    'assets/images/red_panda.jpg',
    'assets/images/cat.jpg',
    'assets/images/cats_group.jpg',
    'assets/images/dino.jpg',
    'assets/images/user_upload_1.png',
  ];

  static String getImageForLevel(int level) {
    if (level <= 10) {
      return easyImages[(level - 1) % easyImages.length];
    } else if (level <= 20) {
      return mediumImages[(level - 11) % mediumImages.length];
    } else {
      return hardImages[(level - 21) % hardImages.length];
    }
  }
}
