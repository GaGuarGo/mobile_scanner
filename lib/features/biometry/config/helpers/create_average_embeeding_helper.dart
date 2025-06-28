List<double> createAverageEmbedding(List<List<double>> allEmbeddings) {
  if (allEmbeddings.isEmpty) return [];
  final int embeddingSize = allEmbeddings.first.length;
  final List<double> averageEmbedding = List.filled(embeddingSize, 0.0);
  for (final List<double> embedding in allEmbeddings) {
    for (int i = 0; i < embeddingSize; i++) {
      averageEmbedding[i] += embedding[i];
    }
  }
  for (int i = 0; i < embeddingSize; i++) {
    averageEmbedding[i] /= allEmbeddings.length;
  }
  return averageEmbedding;
}